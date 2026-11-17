-- Team-up requests: "Team up" on a waiting open duo becomes a request the
-- party's P1 accepts/declines, instead of an instant claim. One live (pending,
-- unexpired) request per requester is enforced in the API; the partial index
-- keeps that lookup cheap.
CREATE TABLE IF NOT EXISTS team_up_requests (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  party_id         INTEGER NOT NULL REFERENCES queue_parties(id) ON DELETE CASCADE,
  requester_user_id INTEGER NOT NULL REFERENCES users(id),
  created_at       INTEGER NOT NULL,
  status           TEXT NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending', 'accepted', 'declined', 'expired'))
);
CREATE INDEX IF NOT EXISTS idx_team_up_party
  ON team_up_requests (party_id, status);
-- one live request per requester: pending rows only (expiry is lazy)
CREATE INDEX IF NOT EXISTS idx_team_up_requester_pending
  ON team_up_requests (requester_user_id) WHERE status = 'pending';
