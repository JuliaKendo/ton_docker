#!/bin/bash
if [ "$1" = "npm" ] || [ "$1" = "npx" ]; then
    exec "$@"
else
    exec toncli "$@"
fi
