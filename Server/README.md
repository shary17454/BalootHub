# Authoritative Baloot rooms

The Node HTTP boundary owns private rooms, bearer sessions, four seats, room
transactions, revision checks and bounded requests. A private pipe connects it to
the original Swift `BalootEngine`; bidding, declarations, legal moves and scores
are not reimplemented in JavaScript or delegated to untrusted clients.

Only a player's own hand and legal choices reach that player's response. Other
hands, the deck, random seed, full game state and action history never leave the
server. Rooms expire after 30 minutes idle or four hours total. Rooms are in memory
and do not survive a deploy/restart. There is no voice/chat, account database,
public room list or real-money play.

Build: `swift build -c release --package-path Server/EngineWorker` then
`cd Server && npm test`. Start with `node Server/server.mjs` from the repository.
Docker build context is the root and Dockerfile is `Server/Dockerfile`.
Healthcheck: `/health`; protocol routes: `/v1/rooms`,
`/v1/rooms/{code}/join`, `ready`, `start`, `action`, `next`, `leave`.
Authenticated `GET /v1/rooms/{code}` provides a private seat snapshot.
Mutating actions carry the observed revision and choice index. Unknown sessions,
stale revisions, wrong turns, host impersonation and full rooms are rejected.
