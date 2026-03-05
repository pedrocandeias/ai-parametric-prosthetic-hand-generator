PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    username      TEXT    NOT NULL UNIQUE COLLATE NOCASE,
    email         TEXT    NOT NULL UNIQUE COLLATE NOCASE,
    password_hash TEXT    NOT NULL,
    role          TEXT    NOT NULL DEFAULT 'user'
        CHECK (role IN ('admin', 'tech', 'user')),
    is_active     INTEGER NOT NULL DEFAULT 1,
    created_at    TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS tech_assignments (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    tech_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_by INTEGER NOT NULL REFERENCES users(id),
    assigned_at TEXT    NOT NULL DEFAULT (datetime('now')),
    UNIQUE (tech_id, user_id)
);

CREATE TABLE IF NOT EXISTS configurations (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    model_id   TEXT    NOT NULL,
    name       TEXT    NOT NULL,
    parameters TEXT    NOT NULL,  -- JSON blob
    notes      TEXT    DEFAULT '',
    created_at TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash TEXT    NOT NULL UNIQUE,  -- SHA-256 of opaque token
    expires_at TEXT    NOT NULL,
    created_at TEXT    NOT NULL DEFAULT (datetime('now')),
    revoked    INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS anthropometric_profiles (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    group_name  TEXT    NOT NULL,          -- e.g. "Northern European Adult Female"
    country     TEXT,                      -- e.g. "Norway", "Scandinavia", "Global"
    gender      TEXT    CHECK(gender IN ('male','female','mixed','other')),
    age_group   TEXT,                      -- e.g. "adult", "child", "elderly"
    percentile  TEXT,                      -- e.g. "5th", "50th", "95th"
    sample_size INTEGER,                   -- number of subjects in dataset
    data_source TEXT,                      -- citation, study name, or standard
    notes       TEXT,
    measurement_source TEXT NOT NULL DEFAULT 'manual',
    profile             TEXT NOT NULL,     -- JSON: full AnthropometricProfile
    geometry_parameters TEXT NOT NULL,     -- JSON: computed model parameter vector
    ai_context          TEXT NOT NULL,     -- JSON: AI reasoning context
    schema_version      TEXT NOT NULL DEFAULT '1.0',
    created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_configurations_user ON configurations(user_id);
CREATE INDEX IF NOT EXISTS idx_assignments_tech    ON tech_assignments(tech_id);
CREATE INDEX IF NOT EXISTS idx_refresh_user        ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_anthro_country ON anthropometric_profiles(country);
CREATE INDEX IF NOT EXISTS idx_anthro_gender  ON anthropometric_profiles(gender);
