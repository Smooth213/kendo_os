# Firestore Public Schema

```text
/organizations
  └─ {dojoId}
       ├─ members
       │    └─ {userId}
       ├─ players
       │    └─ {playerId}
       ├─ teams
       │    └─ {teamId}
       └─ tournaments
            └─ {tournamentId}
                 ├─ programs
                 │    └─ {programId}
                 ├─ matches
                 │    └─ {matchId}
                 └─ audit_logs
                      └─ {logId}
```
