#!/bin/bash
dlAPK() {
	echo -e "##################################"
	echo -e "APK DL"
	echo -e "##################################"
	printMEH "- Preparing the raw APK to use"
	# If we already have a raw APK within /apks/, we want to use it. -r=true to refresh it from the ADB device.
	[ -z ${ADB_SOURCE_DEVICE} ] && printNOK "\t> No source device specied to download the app (--s)" && exit -1
	[ ! -f ${RAW_APK} ] && printNOK "\t> No local APK found ($RAW_APK)"

	# Opening the wanted package within the store and waiting a bit for the "Install" button to appear
	printMEH "- Opening the store app's page within $ADB_SOURCE_DEVICE. Please download the app from the playstore on $ADB_SOURCE_DEVICE"
	adb -s ${ADB_SOURCE_DEVICE} shell am start -a android.intent.action.VIEW -d 'market://details?id='${APK_TO_DL} >/dev/null

	# Checking that the app has been downloaded on the source
	APK_PACKAGE=$(adb -s ${ADB_SOURCE_DEVICE} shell pm path ${APK_TO_DL} | grep base.apk | sed 's/package://')
	if [ -z $APK_PACKAGE ]; then
		printNOK "\t- No package onto the device.. Check the app install"
		exit -1
	fi

	# Fetching the app from the source, once downloaded. We cp it within /app/rawPK
	adb -s ${ADB_SOURCE_DEVICE} pull ${APK_PACKAGE} ${RAW_APK} >/dev/null
	cp ${RAW_APK} "$APP_RAW_APK_PATH/$APP_NAME.apk"
	[ $? -eq 0 ] && printOK "\t> APK DL oké"
}
backupApp() {
	if backupOrDelete $APP_RAW_APK RAW_APK; then return; fi
	dlAPK
}
backupOrDelete() {
	in=$1
	type=$2
	if [ ! -z $BACKUP_EXISTING_OUTPUT ]; then
		printMEH "\t> Backup existing $in"
		backupArch $type $in
	elif [[ (-f $in || -d $in) && -z $OVERWRITE_EXISTING_OUTPUT ]]; then
		printOK "> $in exists, skipping (--ow=1|2 to overwrite)"
		return 0
	elif [ ! -z $OVERWRITE_EXISTING_OUTPUT ]; then
		printNOK "> $in exists + --ow -> overwriting $in"
		rm -rf $in
	fi
	return 1
}
installAPK() {
	echo -e "##################################"
	echo -e "APK install"
	echo -e "##################################"
	# If we have an app within /patchedPK
	if [ ! -f $APP_PATCHED_APK ]; then
		printNOK "\t> No APK in $APP_PATCHED_APK. Run --rec=true."
		exit 1
	fi
	uninstallAPK
	# Installing towards the source
	printMEH "- Installing $APP_PATCHED_APK.."
	adb -s ${ADB_DESTINATION_DEVICE} install ${APP_PATCHED_APK} >/dev/null
	[ $? -eq 0 ] && printOK "\t> Install oké"
}
uninstallAPK() {
	# If we have a previous version installed within the destination
	if [ ! -z $(adb -s $ADB_DESTINATION_DEVICE shell pm path $APK_TO_DL | grep -E ".*.apk") ]; then
		printMEH "- Uninstalling previous version of $APK_TO_DL.."
		adb -s ${ADB_DESTINATION_DEVICE} uninstall ${APK_TO_DL} >/dev/null
		[ $? -eq 0 ] && printOK "\t> Oké"
	fi
}
