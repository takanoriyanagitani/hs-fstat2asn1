#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Building..."
cabal build

echo "Build done"
