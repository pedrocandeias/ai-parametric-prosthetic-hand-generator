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
#   ./deploy.sh deploy <user@host:/path> [--out DIR] [--delete] [--yes]
#       Run collect, then rsync the staged tree to the remote destination.
#       --delete removes remote files no longer present locally.
#
# Examples:
#   ./deploy.sh collect --tar
#   ./deploy.sh deploy deploy@example.com:/var/www/prosthetic-hand --delete
#
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUT_DIR="${SCRIPT_DIR}/deploy"
MAKE_TAR=false
RSYNC_DELETE=false
ASSUME_YES=false
DESTINATION=""

# Files and directories that must NEVER reach the server, or that the server
# rebuilds for itself. Patterns are matched by rsync (basename unless anchored).
EXCLUDES=(
    # --- secrets & local runtime state (critical: never ship) ---
    ".env"                              # API keys / JWT secret  (.env.example IS shipped)
    "config.json"                       # deprecated secrets file
    "data/"                             # dev SQLite DB — server creates its own on first run
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
    "config.example.json"
    "TODO.MD"
    # --- the deploy machinery itself ---
    "deploy/"
    "deploy.sh"
)

usage() {
    sed -n '2,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
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

# Push the staged tree to the remote destination.
do_deploy() {
    do_collect

    echo "=========================================="
    echo "  Deploying to remote"
    echo "=========================================="
    echo "Destination: ${DESTINATION}"
    [ "${RSYNC_DELETE}" = true ] && echo "Mode: mirror (--delete: removes stale remote files)"
    echo ""

    if [ "${ASSUME_YES}" != true ]; then
        read -r -p "Continue with deployment? (y/N) " reply
        case "${reply}" in
            [Yy]*) ;;
            *) echo "Deployment cancelled."; exit 0 ;;
        esac
    fi

    local rsync_args=(-avz --progress)
    [ "${RSYNC_DELETE}" = true ] && rsync_args+=(--delete)
    rsync "${rsync_args[@]}" "${OUT_DIR}/" "${DESTINATION}/"

    echo ""
    echo "=========================================="
    echo "✅ Upload complete"
    echo "=========================================="
    cat <<EOF

Next steps on the server (${DESTINATION##*:}):
  1. cd ${DESTINATION##*:}
  2. cp .env.example .env   &&   edit .env  (JWT_SECRET + API keys)
  3. npm ci --omit=dev      # compiles native modules for this machine
  4. node scripts/create-admin.js <username> <email> <password>   # first run only
  5. npm start              # or run under pm2/systemd
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

if [ "${MODE}" = "deploy" ] && [ -z "${DESTINATION}" ]; then
    echo "❌ deploy mode requires a destination, e.g. user@host:/path" >&2
    echo ""
    usage 1
fi

case "${MODE}" in
    collect) do_collect ;;
    deploy)  do_deploy ;;
esac
