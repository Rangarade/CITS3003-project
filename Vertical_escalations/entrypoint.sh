#!/bin/bash
set -e

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

exec su - hex
