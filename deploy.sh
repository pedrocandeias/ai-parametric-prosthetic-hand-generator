#!/bin/bash
#
# Deployment helper for the AI Parametric Prosthetic Hand Generator.
#
# This app is a Node.js/Express server (it serves the static frontend itself),
# so "deploying" means shipping the source tree — minus secrets, the dev
# database, node_modules, and local tooling — then running `npm ci` + `npm start`
# on the server.
#
# Modes:
#   ./deploy.sh collect [--out DIR] [--tar]
#       Stage every server-bound file into DIR (default ./deploy). With --tar,
#       also produce DIR.tar.gz. Nothing leaves the machine.
#
#   ./deploy.sh deploy [user@host:/path] [--port N] [--dry-run] [--no-backup]
#                      [--out DIR] [--delete] [--yes]
#       Run collect, back up the remote (DB + code tarball into backups/), then
#       rsync the staged tree up. With no destination it uses the cPanel target
#       configured below. No --delete by default, so server-only files
#       (Passenger .htaccess, the live data/ DB) are preserved.
#
# Examples:
#   ./deploy.sh collect --tar
#   ./deploy.sh deploy                       # → configured cPanel target
#   ./deploy.sh deploy --dry-run             # preview, no changes
#   ./deploy.sh deploy user@host:/path --port 2222
#
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUT_DIR="${SCRIPT_DIR}/deploy"
MAKE_TAR=false
RSYNC_DELETE=false
ASSUME_YES=false
DESTINATION=""
DRY_RUN=false
DO_BACKUP=true

# --- Default cPanel deploy target (same account as bragagenda) ----------------
# Override the destination by passing user@host:/path; override the SSH port
# with --port. The app runs under cPanel's "Setup Node.js App" (Passenger).
REMOTE_USER="pedrocan"
REMOTE_HOST="pedrocandeias.net"
REMOTE_PORT="22"
REMOTE_PATH="/home/pedrocan/public_html/sites/handfab"

# Files and directories that must NEVER reach the server, or that the server
# rebuilds for itself. Patterns are matched by rsync (basename unless anchored).
EXCLUDES=(
    # --- secrets & local runtime state (critical: never ship) ---
    ".env"                              # API keys / JWT secret  (.env.example IS shipped)
    "config.json"                       # deprecated secrets file
    "data/"                             # dev SQLite DB — server creates its own on first run
    # --- server-managed: cPanel/Passenger owns the app-root .htaccess ---
    ".htaccess"                         # NEVER ship: would wipe the CloudLinux Passenger block
    # --- dependencies: reinstalled on the server with `npm ci` ---
    "node_modules/"                     # native modules (better-sqlite3, bcrypt) are arch-specific
    # --- version control ---
    ".git/"
    ".gitignore"
    # --- local tooling, editor & OS cruft ---
    ".claude/"
    "memory/"
    ".vscode/"
    ".idea/"
    "*.swp"
    "*.swo"
    "*~"
    ".DS_Store"
    "Thumbs.db"
    "*.code-workspace"
    "*.log"
    # --- tests & dev-only artifacts ---
    "tests/"
    "test-results/"
    "test-renders/"
    "playwright.config.js"
    "public/"                           # old/scratch frontend sources
    # --- reference / deprecated material ---
    "Hand Fab prosthetic configurator/"
    "models/old_models/"
    "models/reconstruction/"            # STL→SCAD reconstruction sources (dev-only)
    "config.example.json"
    "TODO.MD"
    # --- scratch / in-progress build artifacts (dev-only, never ship) ---
    "_assembly.*"                       # merged-assembly render scratch (.scad/.stl/.3mf/.png/.json)
    "*_preview.png"                     # per-model preview renders
    "assemblage-*.jpg"                  # reference exploded-view photos
    "models/*/*/output/"                # openscad-skill render output (STL/PNG scratch)
    "models/*/*/previews/"              # openscad-skill preview PNGs
    # --- the deploy machinery itself ---
    "deploy/"
    "deploy.sh"
)

usage() {
    cat <<'USAGE'
Deployment helper for the AI Parametric Prosthetic Hand Generator.

Usage:
  ./deploy.sh collect [--out DIR] [--tar]
      Stage the deployable tree locally (default ./deploy). --tar also makes a .tar.gz.

  ./deploy.sh deploy [user@host:/path] [--port N] [--dry-run] [--no-backup] [--delete] [--yes]
      collect → remote backup → rsync up. No destination = the configured cPanel target.
      No --delete by default (preserves Passenger .htaccess, the live data/ DB, etc.).

Examples:
  ./deploy.sh collect --tar
  ./deploy.sh deploy                 # configured cPanel target
  ./deploy.sh deploy --dry-run       # preview only
  ./deploy.sh deploy user@host:/path --port 2222
USAGE
    exit "${1:-0}"
}

# Build the rsync --exclude argument list from EXCLUDES.
rsync_excludes() {
    local args=()
    for pattern in "${EXCLUDES[@]}"; do
        args+=(--exclude="${pattern}")
    done
    printf '%s\n' "${args[@]}"
}

# Stage the deployable tree into OUT_DIR.
do_collect() {
    echo "=========================================="
    echo "  Collecting deployable files"
    echo "=========================================="
    echo "Source: ${SCRIPT_DIR}"
    echo "Output: ${OUT_DIR}"
    echo ""

    mapfile -t EXCLUDE_ARGS < <(rsync_excludes)

    rm -rf "${OUT_DIR}"
    mkdir -p "${OUT_DIR}"
    rsync -a "${EXCLUDE_ARGS[@]}" "${SCRIPT_DIR}/" "${OUT_DIR}/"

    # --- Safety net: refuse to continue if a secret or the DB slipped through ---
    for forbidden in ".env" "config.json" "data"; do
        if [ -e "${OUT_DIR}/${forbidden}" ]; then
            echo "❌ Refusing to proceed: '${forbidden}' was staged into ${OUT_DIR}" >&2
            echo "   Remove it from the package and check the EXCLUDES list." >&2
            exit 1
        fi
    done

    local count size
    count=$(find "${OUT_DIR}" -type f | wc -l | tr -d ' ')
    size=$(du -sh "${OUT_DIR}" | cut -f1)
    echo "✅ Staged ${count} files (${size}) into ${OUT_DIR}"

    if [ "${MAKE_TAR}" = true ]; then
        local tarball="${OUT_DIR}.tar.gz"
        tar -czf "${tarball}" -C "$(dirname "${OUT_DIR}")" "$(basename "${OUT_DIR}")"
        echo "📦 Archive: ${tarball} ($(du -sh "${tarball}" | cut -f1))"
    fi
    echo ""
}

# Back up the remote app (DB + code tarball) before we overwrite anything.
# Safe to run before the very first deploy: if the app dir does not exist yet
# the remote shell exits 0 and nothing is backed up.
remote_backup() {
    local ssh_target="$1" dest_path="$2"
    echo "→ Backing up remote (skipped if the app dir does not exist yet)…"
    ssh -p "${REMOTE_PORT}" "${ssh_target}" "
        cd '${dest_path}' 2>/dev/null || exit 0
        mkdir -p backups
        ts=\$(date +%Y%m%d-%H%M%S)
        if [ -f data/app.db ]; then
            sqlite3 data/app.db \".backup 'backups/app-\${ts}.db'\" 2>/dev/null \
                || cp data/app.db \"backups/app-\${ts}.db\" 2>/dev/null || true
        fi
        tar -czf \"backups/code-\${ts}.tar.gz\" \
            --exclude=./data --exclude=./node_modules --exclude=./backups \
            . 2>/dev/null || true
    " && echo "  backup done." || echo "  ⚠ backup step reported a problem (continuing)."
    echo ""
}

# Push the staged tree to the remote destination.
do_deploy() {
    do_collect

    # Default to the configured cPanel target when no destination was given.
    if [ -z "${DESTINATION}" ]; then
        DESTINATION="${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"
    fi
    local ssh_target="${DESTINATION%%:*}"
    local dest_path="${DESTINATION#*:}"

    echo "=========================================="
    echo "  Deploying to remote"
    echo "=========================================="
    echo "Destination: ${DESTINATION}  (ssh port ${REMOTE_PORT})"
    [ "${DRY_RUN}" = true ]      && echo "Mode: DRY RUN (no changes will be made)"
    [ "${RSYNC_DELETE}" = true ] && echo "Mode: mirror (--delete: removes stale remote files)"
    if [ "${DO_BACKUP}" = true ] && [ "${DRY_RUN}" != true ]; then
        echo "Backup: remote DB + code tarball → ${dest_path}/backups/"
    fi
    echo ""

    if [ "${ASSUME_YES}" != true ] && [ "${DRY_RUN}" != true ]; then
        read -r -p "Continue with deployment? (y/N) " reply
        case "${reply}" in
            [Yy]*) ;;
            *) echo "Deployment cancelled."; exit 0 ;;
        esac
    fi

    if [ "${DO_BACKUP}" = true ] && [ "${DRY_RUN}" != true ]; then
        remote_backup "${ssh_target}" "${dest_path}"
    fi

    local rsync_args=(-avz --progress -e "ssh -p ${REMOTE_PORT}")
    [ "${DRY_RUN}" = true ]      && rsync_args+=(--dry-run)
    [ "${RSYNC_DELETE}" = true ] && rsync_args+=(--delete)
    rsync "${rsync_args[@]}" "${OUT_DIR}/" "${DESTINATION}/"

    [ "${DRY_RUN}" = true ] && { echo ""; echo "(DRY RUN — nothing was changed.)"; echo ""; return 0; }

    # cPanel "Application root" is relative to the home dir.
    local app_root="${dest_path#/home/${ssh_target#*@}/}"

    echo ""
    echo "=========================================="
    echo "✅ Upload complete"
    echo "=========================================="
    cat <<EOF

First deploy only — set up the Node.js app in cPanel:
  1. Setup Node.js App → Create Application
       Application root        = ${app_root}
       Application startup file = server/index.js
       Application mode        = Production   (Node 18 or 20 LTS)
  2. Environment variables (in the panel): JWT_SECRET, ANTHROPIC_API_KEY,
     OPENAI_API_KEY, NODE_ENV=production
  3. Run NPM Install   (compiles bcrypt + better-sqlite3 on the server)
  4. node scripts/create-admin.js <username> <email> <password>   # via the panel's venv shell
  5. Restart the app in the panel

Subsequent deploys: re-run ./deploy.sh deploy, then click Restart in the panel.
EOF
    echo ""
}

# --- Argument parsing ---------------------------------------------------------
[ $# -eq 0 ] && usage 1
MODE="$1"; shift

case "${MODE}" in
    -h|--help|help) usage 0 ;;
    collect|deploy) ;;
    *) echo "Unknown mode: '${MODE}'" >&2; echo ""; usage 1 ;;
esac

while [ $# -gt 0 ]; do
    case "$1" in
        --out)    OUT_DIR="$2"; shift 2 ;;
        --out=*)  OUT_DIR="${1#*=}"; shift ;;
        --tar)    MAKE_TAR=true; shift ;;
        --delete) RSYNC_DELETE=true; shift ;;
        --port)   REMOTE_PORT="$2"; shift 2 ;;
        --port=*) REMOTE_PORT="${1#*=}"; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --no-backup) DO_BACKUP=false; shift ;;
        -y|--yes) ASSUME_YES=true; shift ;;
        -h|--help) usage 0 ;;
        -*)       echo "Unknown option: '$1'" >&2; usage 1 ;;
        *)
            if [ "${MODE}" = "deploy" ] && [ -z "${DESTINATION}" ]; then
                DESTINATION="$1"; shift
            else
                echo "Unexpected argument: '$1'" >&2; usage 1
            fi
            ;;
    esac
done

# Normalise OUT_DIR to an absolute path (handles a relative --out).
case "${OUT_DIR}" in
    /*) ;;
    *) OUT_DIR="$( cd "$( dirname "${OUT_DIR}" )" 2>/dev/null && pwd )/$( basename "${OUT_DIR}" )" || OUT_DIR="${SCRIPT_DIR}/deploy" ;;
esac

case "${MODE}" in
    collect) do_collect ;;
    deploy)  do_deploy ;;
esac
