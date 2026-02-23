#!/bin/sh

echo "Building with HIE file generation for Weeder..."
cabal build all --ghc-options="-fwrite-ide-info"

echo "Running Weeder..."
weeder
