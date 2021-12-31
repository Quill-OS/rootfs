#!/bin/sh

mkdir -p /data/storage/gutenberg && cd /data/storage/gutenberg

# Preventing abusive sync
date +%s > /data/storage/gutenberg/last_sync

# Fetching catalog
rm -f catalog.csv
wget -O catalog.csv http://www.gutenberg.org/cache/epub/feeds/pg_catalog.csv || exit 1

cd -
sync
