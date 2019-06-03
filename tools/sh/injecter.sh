#!/bin/bash
patch(){
	echo -e "##################################"
	echo "Injecting"
	echo -e "##################################"
	# Every SMALI file of the decompiled app source
	printMEH "- Scanning for smali files.."
	# If we don't have any SMALI folder, we can't work
	if [ ! -d ${DECOMPILED_APP_PATH} ]; then printNOK "\t> We don't have any SMALI for ${APP_NAME}. Run --dec=true first."; exit -1; fi
	SMALI_CANDIDATE_FILES=$(find ${APP_DIR}/smali -name '*.smali' | wc -l | sed 's/ //g')
	printOK "\t> ${SMALI_CANDIDATE_FILES} files to find and bypass the checkServerTrusted function within the ${APP_NAME} SMALI arch.."
	# Every SMALI file that contain the checkServerTrusted function reference
	CANDIDATE_FILES=$(grep -rl 'method public checkServerTrusted' ${APP_DIR}/smali/)
	printOK "\t> Found $(echo "${CANDIDATE_FILES}" | wc -l | sed 's/ //g') candidate files"
	# For each file
	for f in $CANDIDATE_FILES; do
		echo "------------------------------"
		printMEH "Candidate file to patch: "$f
		NB_LINE=$(awk '/method public checkServerTrusted/,/\.end method/' $f | wc -l | psed 's/ //g')
		if [ $NB_LINE -lt 8 ]
		then
			printMEH "\t-> Bypassing (fn is harmless, $NB_LINE lines long).."
			continue;
		fi
		printOK "$NB_LINE lines long"
		# Editing the found SMALI file within our node script
		node ${TOOLS_PATH}/js/inject $f checkServerTrusted   
	done
}

