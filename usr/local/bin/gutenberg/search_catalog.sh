#!/bin/bash

[ -z "${1}" ] && echo "Error. Please provide the 'search term' argument." && exit 1

SEARCH_TERM="${1}"

SEARCH=$(cat /data/storage/gutenberg/catalog.csv | cut -d ',' -f '4' | grep -ni "${SEARCH_TERM}")
SEARCH_IDS_LINES=$(echo "${SEARCH}" | cut -d ":" -f 1)
SEARCH_TITLES=$(echo "${SEARCH}" | awk -F: '{ print $NF }')

if [ ! -z "${SEARCH_IDS_LINES}" ] && [ ! -z "${SEARCH_TITLES}" ]; then
	rm -rf /kobo/inkbox/gutenberg-search/
	mkdir -p /kobo/inkbox/gutenberg-search/

	while read id_line; do
		id=$(cat /data/storage/gutenberg/catalog.csv | sed -n ${id_line}p | cut -d ',' -f '1')
		echo "${id}" >> /kobo/inkbox/gutenberg-search/search_results_raw
	done <<< "${SEARCH_IDS_LINES}"

	echo >> /kobo/inkbox/gutenberg-search/search_results_raw

	while read title; do
		if [ "${title:0:1}" == '"' ]; then
			title=$(echo "${title}" | cut -c 2-)
		fi
		echo "${title}" >> /kobo/inkbox/gutenberg-search/search_results_raw
	done <<< "${SEARCH_TITLES}"

	# IDs list
	cat /kobo/inkbox/gutenberg-search/search_results_raw | sed -n '/^$/q;p' > /kobo/inkbox/gutenberg-search/search_results_ids
	# Titles list
	tac /kobo/inkbox/gutenberg-search/search_results_raw | sed -n '/^$/q;p' | tac > /kobo/inkbox/gutenberg-search/search_results_titles

	echo "Found the following matching results:"
	paste /kobo/inkbox/gutenberg-search/search_results_ids /kobo/inkbox/gutenberg-search/search_results_titles | tee /kobo/inkbox/gutenberg-search/search_results_combined
	echo "true" > /kobo/inkbox/gutenberg-search/search_done
	exit 0
else
	echo "No matching results found."
	echo "false" > /kobo/inkbox/gutenberg-search/search_done
	exit 1
fi
