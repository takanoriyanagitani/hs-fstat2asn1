#!/bin/sh

find . -type f -name '*.hs' |
    sed -n -e /dist-newstyle/d -e p |
	xargs \
		fourmolu \
		--no-cabal \
		--mode inplace
