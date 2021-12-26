#!/bin/sh

mkdir -p /data/storage/gutenberg && cd /data/storage/gutenberg
wget https://www.gutenberg.org/cache/epub/feeds/pg_catalog.csv
sync
