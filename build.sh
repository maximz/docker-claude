#!/bin/bash
set -e
cd "$(dirname "$0")"

# Build cc-open base first (cc derives from it)
echo "Building cc-open base image..."
docker build -t cc-open -f Dockerfile.open .

echo "Building cc (firewalled) image..."
docker build -t cc -f Dockerfile .
