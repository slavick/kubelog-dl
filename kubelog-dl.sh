#!/usr/bin/env bash

# Ensure we are in the prod namespace
kubectx prod

apps=""
if [ -d $1 ]; then
	# if the argument is a directory, use the subdirectory names as app names
	cd $1
	apps=`ls -d */ | cut -f1 -d'/'`
fi

for app in $apps
do
	echo $app
	cd $app

	# get the current pods that match the $app argument and cut out the pod name
	current_pods=`kubectl get po | grep $app | cut -d' ' -f1`

	if [[ ! -z $current_pods ]]; then
		while IFS= read -r pod; do
			if [ -f $pod ]; then
				echo "Skipping $pod (already exists)"
				continue
			fi

			# use the pod's name as the filename as it is unique
			echo "Downloading $pod"
			kubectl logs $pod > $pod

			# execute rules defined in filters.conf if it exists
			if [ -f filters.conf ]; then
				while IFS=, read -r property filter; do
					echo "filtering $pod lines for [$filter] to get [$property]"

					# create output filenames for filter result files
					filtername=$(echo $filter | tr " " _)	# replace spaces with underscores
					filterfile="$pod-$filtername"			# file to contain lines that match filter
					propertyfile="$filterfile-$property"	# file to contain $property from filtered lines
					rm -f $filterfile $propertyfile			# delete the filter output files (prevent duplicating results on repeat runs)

					# write matching lines to filterfile
					grep "$filter" $pod > $filterfile

					# get latest result for this filter-property
					prev=`ls *"$filtername-$property" | tail -1`

					# extract the property from filterfile
					while read -r match; do
						# echo:			`{"account_id":"omg-ac_01D1VSG2C1WHSNQ1DQF4KVTE8T","message":"message"}
						# gron+grep:	`json.account_id = "omg-ac_01D1VSG2C1WHSNQ1DQF4KVTE8T";`
						# cut:			` "omg-ac_01D1VSG2C1WHSNQ1DQF4KVTE8T";`
						# tr:			`omg-ac_01D1VSG2C1WHSNQ1DQF4KVTE8T`
						echo $match | gron | grep $property | cut -d"=" -f2 | tr -d ' ";' >> $propertyfile
					done < $filterfile

					if [ -f $propertyfile ]; then
						# sort and remove duplicates from the filter property output file
						sort -u -o $propertyfile $propertyfile

						# diff the previous run with the run we just created
						diff $prev $propertyfile > "$propertyfile-diff"
						cat "$propertyfile-diff" # output the diff so it's included in the mail message
					fi
				done < filters.conf
			fi
		done <<< $current_pods
	fi

	# cd back to base directory
	cd ..

	# delete empty files
	find . -empty -delete
done
