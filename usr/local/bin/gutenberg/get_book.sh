#!/bin/sh

[ -z "${1}" ] && echo "Error. Please provide the 'id' argument." && exit 1
ID="${1}"

if [ "${2}" != "cover" ]; then
	wget -O "/data/onboard/${ID}.epub" "http://gutenberg.org/ebooks/${ID}.epub.noimages"
	[ ${?} != 0 ] && rm -f "/data/onboard/${ID}.epub" && exit 1
else
	mkdir -p /kobo/inkbox/gutenberg
	wget -O "/kobo/inkbox/gutenberg/book_cover.jpg" "http://gutenberg.org/files/${ID}/${ID}-h/images/cover.jpg"
	[ ${?} != 0 ] && rm -f "/kobo/inkbox/gutenberg/book_cover.jpg" && exit 1
fi

exit 0
