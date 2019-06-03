#!/bin/bash
dlAPK(){
	echo -e "##################################"
	echo -e "APK DL"
	echo -e "##################################"
	printMEH "- Preparing the raw APK to use"
	# If we already have a raw APK within /apks/, we want to use it. -r=true to refresh it from the ADB device.
	if [ -f ${RAW_APK} ]; then 
		printOK "\t> We already have a local APK for ${RAW_APK}"
		# Backup
		if [ ${BACKUP_EXISTING} -eq 1 ]; then backupArch APK ${RAW_APK}; 
		# Skip process and use /apks/*.apk if exists
		elif [ ${BACKUP_EXISTING} -eq 2 ]; then 
			if [ ! -z ${SOURCE} ]; then printNOK "\t\t > Overriding the -s argument with the local file. Run with -r=true to load the device's raw APK."; fi;
			printMEH "\t> Copying ${RAW_APK} in ${RAW_APK_CLEANED_PATH}"
			cp "${RAW_APK}" ${RAW_APK_CLEANED_PATH}
			# We have the copy of /apks/*.apk in /rawPK/*.apk
			if [ $? -eq 0 ]; then printOK "\t\t> APK copy within ${RAW_APK_CLEANED_PATH} oké";
			else printNOK "\t> APK copy within ${RAW_APK_CLEANED_PATH} failed. Re-run or check fs/sh rights."; exit -1; fi; return
		# Delete existing and re-get a raw APK 
		elif [ ${DELETE_EXISTING} -eq 1 ]; then 
			printNOK "\t> Deleting existing.. "
			# Remove the /apks/rawPK/*.apk
			rm "${RAW_APK}"
			# Remove the /app/rawPK/*.apk
			rm "${RAW_APK_CLEANED_PATH}/${APP_NAME}.apk"
			# Get a fresh APK from the device
			dlAPK
		fi
		return
	# We don't have any local APK. We must have a source + a package ID for us to work
	else
		printNOK "\t> No local APK found (${RAW_APK})"
		if [ -z ${SOURCE} ]; then printNOK "\t> No source device specified to download the app (--s)"; exit -1;
		# Package ID is a requirement for us to uninstall/install the APK later
		elif [ -z ${APK_TO_DL} ]; then printNOK "\t- No package specified (--p)"; exit -1; fi
	fi

	# Opening the wanted package within the store and waiting a bit for the "Install" button to appear
	printMEH "- Opening the store app's page within ${ADB_SOURCE_DEVICE}.."
	adb -s ${ADB_SOURCE_DEVICE} shell am start -a android.intent.action.VIEW -d 'market://details?id='${APK_TO_DL} > /dev/null 
	printMEH "\t> Waiting 3 seconds for the store to display the wanted package.."
	wait_time 3

	# Taping at the correct X Y, on "Install"
	adb -s ${ADB_SOURCE_DEVICE} shell input touchscreen tap ${XTAP} ${YTAP}
	printOK "\t> App should be currently installing onto ${ADB_SOURCE_DEVICE}"
	printMEH "\t\t> Press ENTER when fully installed"
	read  -n 1

	# Checking that the app has been downloaded on the source
	APK_PACKAGE=$(adb -s ${ADB_SOURCE_DEVICE} shell pm path ${APK_TO_DL} | grep base.apk | sed 's/package://')
	if [ -z ${APK_PACKAGE} ]; then printNOK "\t- No package onto the device.. Check the app install"; exit -1; fi; 

	# Fetching the app from the source, once downloaded. We cp it within /app/rawPK
	adb -s ${ADB_SOURCE_DEVICE} pull ${APK_PACKAGE} ${RAW_APK} > /dev/null
	cp ${RAW_APK} "${RAW_APK_CLEANED_PATH}/${APP_NAME}.apk";
	if [ $? -eq 0 ]; then printOK "\t\t> APK DL oké"; fi;
}
installAPK(){
	echo -e "##################################"
	echo -e "APK install"
	echo -e "##################################"
	# If we have an app within /patchedPK
	if [ ! -f ${PATCHED_APK} ]; then printNOK "\t> No APK in ${PATCHED_APK}. Run --rec=true."; exit 1;  fi;
	# If we have a previous version installed within the destination
	if [ ! -z $(adb -s ${DESTINATION} shell pm path ${APK_TO_DL} | grep -E ".*.apk") ]; then 
		printMEH "- Uninstalling previous version of ${APK_TO_DL}.."; 
		adb -s ${DESTINATION} uninstall ${APK_TO_DL} > /dev/null
		if [ $? -eq 0 ]; then printOK "\t> Uninstall oké"; fi;
	fi;
	# Installing towards the source
	printMEH "- Installing ${PATCHED_APK}.."
	adb -s ${DESTINATION} install ${PATCHED_APK} > /dev/null
	if [ $? -eq 0 ]; then printOK "\t> Install oké"; fi;
}