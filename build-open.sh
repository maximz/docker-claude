#!/bin/bash
set -e
cd "$(dirname "$0")"
docker build -t cc-open -f Dockerfile.open .
