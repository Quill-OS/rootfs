#!/bin/sh

[ -z "${1}" ] && echo "Error. Please provide the 'id' argument." && exit 1
ID="${1}"

wget -O "/data/onboard/${ID}.epub" "http://gutenberg.org/ebooks/${ID}.epub.noimages"
