#!/bin/bash

FV=$(pwd)
RAW=$FV/vatex/raw
VIDS=$RAW/vids

function download_all {
	for F_FILE in "$RAW"/*.ids; do 
		echo "remove later"	
	done
}

function download_select {
	echo "Downloading ${1} videos"
	MAX=$1
	SEEN_ALL=0
	ERR_ALL=0
	for F_FILE in "$RAW"/*.ids; do
		SEEN=0
		ERR=0
		while read -r L; do
			#if the given number of videos has been downloaded, break loop
			if [[ $SEEN -gt $MAX ]]; then 
				echo "Seen a Maximum of ${SEEN} Lines"
				break
			fi 
			#set the string delimiter to "_" to break up each line into an array
			IFS="_" read -r -a ARR <<< $L

			#set video ID
			ID=${ARR[0]} 
			#set clip start time $IN
			IN=${ARR[1]}
			#set clip end time $OUT
			OUT=${ARR[2]}
			#clip duration is (clip end time $OUT - clip start time $IN) = $LN
			LN=$((${OUT}-${IN}))

			#get video file location (e.g. test, val, train)
			IFS="/" read -r -a FARR <<< $F_FILE
			FILE="${FARR[-1]}"
			
			#set expected file name
			NAME=$VIDS/"${FILE}.${ID}.mp4"

			#for every video, download from given time frame	
			echo "Starting Download ${ID}: ${SEEN}/${MAX}"

			#access and download whole video with youtube-dl
			#youtube-dl -f mp4/bestvideo captures video and audio in the best accessible format
			#youtube-dl -q shows no output
			
			#if the download doesn't complete or an error is returned, skip and increment error count
			if (youtube-dl "${ID}" -q -f mp4/bestvideo --external-downloader ffmpeg -o $NAME); then
				echo "-----------------------------------YT-DL DOWNLOADED VIDEO ${ID} 🟦"

				#trim and encode video clip
				#if the encoding doesn't complete or an error is returned, skip and increment error count
				#ffmpeg -loglevel 8 only shows errors that break the download process
				
				if (ffmpeg -ss $IN -t $LN -i $NAME -c:v copy -c:a copy -y ${ID}.mp4); then 
					echo "-----------------------------------FFMPEG TRIMMED VIDEO ${ID} 🟩"
					((SEEN+=1))
				else
					((ERR+=1))
					echo "-----------------------------------FFMPEG FAILED VIDEO ${ID} 🟥"
				fi	
			else 
				echo "-----------------------------------YT-DL FAILED VIDEO ${ID} 🟨"
				((ERR+=1))
			fi
					
		done < $F_FILE
		echo "--Videos Downloaded in ${F_FILE}: ${SEEN}"
		echo "--Videos Skipped in ${F_FILE}: ${ERR}"
		((SEEN_ALL+=SEEN))
		((ERR_ALL+=ERR))
		
	done
	echo ""
	echo "--Total Videos Downloaded: ${SEEN_ALL}"
	echo "--Total Videos Skipped: ${ERR_ALL}"
	RATE=((SEEN_ALL/((SEEN_ALL+ERR_ALL))*100))
	echo "--Download Success Rate: ${RATE}%"
}

if [ -z $1 ]; then
	#dw_all
	test $1
else
	download_select $1
fi
