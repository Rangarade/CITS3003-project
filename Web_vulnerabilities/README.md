# NEON//WIRE — Web Vulnerabilities

Part of the group CTF box. A single themed Flask web portal ("NEON//WIRE GRID
PORTAL", node NW-042) hiding three web vulnerabilities. Same universe as the
network node.

## Challenges (3 flags)

| # | Area | Vulnerability | Flag |
|---|------|---------------|------|
| 1 | `/grid/records` | Blind (boolean) SQL injection | `FLAG{...}` |
| 2 | `/grid/feedback` | Stored XSS → admin cookie theft | `FLAG{...}` |
| 3 | `/grid/ops/template` | Jinja2 SSTI → RCE (admin only) | `FLAG{...}` |

Challenge 2 yields the admin session cookie, which unlocks the admin-only area
where Challenge 3 lives — so 2 → 3 is a chain, and 1 is an independent root.

## Setup — Option A: Docker (recommended)

Brings up the portal **and** the on-call operator bot (needed for the XSS
challenge).

```bash
docker compose up --build      # portal on http://<host>:8080
docker compose down            # stop + remove
```

## Setup — Option B: no Docker

```bash
./run.sh                       # portal on http://<host>:8080
```
Challenges 1 and 3 are fully solvable this way. Challenge 2 also needs the
operator bot — `run.sh` prints the two commands to start it in a second shell.

## Notes for players
- No credentials to find up front — start at `/grid/records`.
- `sqlmap` is not required and (per the unit) not permitted; the SQLi is
  solvable by hand.
- The XSS "operator" reviews the feedback board every ~20s; be patient.

## Integration (for the group VM/init-script)
Self-contained under `Web_vulnerabilities/`. The init script can either run
`docker compose -f Web_vulnerabilities/docker-compose.yml up -d`, or, on a
Docker-less VM, `Web_vulnerabilities/run.sh` (plus the bot command). Only port
**8080** is exposed. Marker-only material (sample solutions, flag list) is under
`marker_only/` — do **not** ship it to other groups.
