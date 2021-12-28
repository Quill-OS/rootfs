#!/bin/sh

[ -z "${1}" ] && echo "Error. Please provide the 'id' argument." && exit 1
ID="${1}"

if [ "${2}" != "cover" ]; then
	wget -O "/data/onboard/${ID}.epub" "http://gutenberg.org/ebooks/${ID}.epub.noimages"
else
	mkdir -p /kobo/inkbox/gutenberg
	wget -O "/kobo/inkbox/gutenberg/book_cover.jpg" "http://gutenberg.org/files/${ID}/${ID}-h/images/cover.jpg"
fi
