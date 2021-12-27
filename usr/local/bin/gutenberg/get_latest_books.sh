#!/bin/bash

mkdir -p /data/onboard/.inkbox/gutenberg-data && cd /data/onboard/.inkbox/gutenberg-data
rm -rf /data/onboard/.inkbox/gutenberg-data/latest-books

# Get the 16 latest books IDs and titles
ID_LIST=$(tac /data/storage/gutenberg/catalog.csv | grep "Text" | cut -d ',' -f '1' | head -n 17 | tac | sed '$ d')
TITLE_LIST=$(tac /data/storage/gutenberg/catalog.csv | grep "Text" | cut -d ',' -f '4' | head -n 17 | tac | sed '$ d')

book_number=1
while read id; do
	mkdir -p latest-books/${book_number}
	echo "${id}" > latest-books/${book_number}/id
	wget -O latest-books/${book_number}/cover.jpg "http://gutenberg.org/files/${id}/${id}-h/images/cover.jpg"
	book_number=$((book_number+1))
done <<< "${ID_LIST}"

book_number=1
while read title; do
	if [ "${title:0:1}" == '"' ]; then
		title_full="${title}"
		title=$(echo "${title}" | cut -c 2-)
	fi

	if [ "${#title}" -gt 25 ]; then
		title_full="${title}"
		title="${title:0:25} ..."
	fi

	echo "${title_full}" > latest-books/${book_number}/title_full
	echo "${title}" > latest-books/${book_number}/title
	book_number=$((book_number+1))
done <<< "${TITLE_LIST}"