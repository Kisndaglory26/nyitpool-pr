-- Guests (nickname + scanned QR key) can now create queue parties, so the
-- creator column can no longer assume a registered user. SQLite cannot alter
-- a column's nullability in place — rebuild the table.
CREATE TABLE IF NOT EXISTS queue_parties_new (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  format           TEXT    NOT NULL CHECK (format IN ('solo', 'duo')),
  status           TEXT    NOT NULL DEFAULT 'waiting'
                   CHECK (status IN ('waiting', 'playing', 'completed', 'skipped')),
  created_by_user_id INTEGER REFERENCES users(id),
  p1_user_id       INTEGER REFERENCES users(id),
  p1_guest_name    TEXT,
  p2_user_id       INTEGER REFERENCES users(id),
  p2_guest_name    TEXT,
  position         INTEGER NOT NULL,
  created_at       INTEGER NOT NULL
);
INSERT INTO queue_parties_new
  (id, format, status, created_by_user_id, p1_user_id, p1_guest_name, p2_user_id, p2_guest_name, position, created_at)
SELECT
  id, format, status, created_by_user_id, p1_user_id, p1_guest_name, p2_user_id, p2_guest_name, position, created_at
FROM queue_parties;
-- skip_votes references queue_parties and is ephemeral (live parties only) —
-- drop it before the parent so the FK constraint lets the rebuild through.
DROP TABLE IF EXISTS skip_votes;
DROP TABLE IF EXISTS queue_parties;
ALTER TABLE queue_parties_new RENAME TO queue_parties;
-- 3-vote consensus skip (one vote per account per party)
CREATE TABLE IF NOT EXISTS skip_votes (
  party_id      INTEGER NOT NULL REFERENCES queue_parties(id) ON DELETE CASCADE,
  voter_user_id INTEGER NOT NULL REFERENCES users(id),
  created_at    INTEGER NOT NULL,
  PRIMARY KEY (party_id, voter_user_id)
);
CREATE INDEX IF NOT EXISTS idx_parties_active ON queue_parties (status, position);
