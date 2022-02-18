#!/bin/sh

[ -z "${1}" ] && echo "Error. Please provide the 'id' argument." && exit 1
ID="${1}"
TITLE="${3}"

if [ "${2}" != "cover" ]; then
	if [ ! -z "${TITLE}" ]; then
		OUT_PATH="/data/onboard/${TITLE}.${ID}.epub"
	else
		OUT_PATH="/data/onboard/${ID}.epub"
	fi
	wget -O "${OUT_PATH}" "http://gutenberg.org/ebooks/${ID}.epub.noimages"
	[ ${?} != 0 ] && rm -f "/data/onboard/${ID}.epub" && exit 1
else
	mkdir -p /kobo/inkbox/gutenberg
	wget -O "/kobo/inkbox/gutenberg/book_cover.jpg" "http://gutenberg.org/files/${ID}/${ID}-h/images/cover.jpg"
	[ ${?} != 0 ] && rm -f "/kobo/inkbox/gutenberg/book_cover.jpg" && exit 1
fi

sync
exit 0
