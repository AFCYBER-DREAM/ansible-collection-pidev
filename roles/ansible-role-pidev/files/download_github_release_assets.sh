#!/usr/bin/env bash

user="${1//[^[:alnum:][:punct:]]}"
repo="${2//[^[:alnum:][:punct:]]}"
label="$3"

num_assets="$(($(jq '.assets | length' ~/.install/$user/$repo/latest_release_metadata.json)-1))"

for num in $(seq 0 $num_assets); \
do \
  eval jq \'.assets[$num]\' ~/.install/$user/$repo/latest_release_metadata.json \
  | while read line; \
    do \
       if [[ $line =~ $label ]]; then \
	echo "$(eval jq -r \'.assets[$num].browser_download_url\' ~/.install/$user/$repo/latest_release_metadata.json)";
      fi;
    done;

done
