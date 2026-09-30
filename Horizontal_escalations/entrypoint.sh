#!/bin/bash
set -e

# Keep the vault rotation daemon alive inside the container.
cron

# Honour an explicit command, otherwise drop the student into VANCE's shell.
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

exec su - vance
