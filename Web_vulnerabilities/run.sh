#!/bin/bash
# Launcher for the web-vulnerabilities box, called by the top-level global
# run.sh. Brings the docker-compose stack up and tears it down cleanly when
# the parent runner sends SIGINT/SIGTERM (so containers don't leak).

cd "$(dirname "$0")"

if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE="docker-compose"
else
    COMPOSE="docker compose"
fi

cleanup() {
    $COMPOSE down >/dev/null 2>&1
    exit 0
}
trap cleanup SIGINT SIGTERM

$COMPOSE down >/dev/null 2>&1
$COMPOSE up --build &
CPID=$!
wait "$CPID"
