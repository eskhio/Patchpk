#!/bin/bash
printOK() {
	green="\x1B[32m"
	echo -e "$green$1\x1B[m"
}
printNOK() {
	red="\x1B[31m"
	echo -e "$red$1\x1B[m"
}
printMEH() {
	yellow="\x1B[33m"
	echo -e "$yellow$1\x1B[m"
}
deletePrompt() {
	toRemove=$1
	type=$2
	backupDest=$3
	[ -z $backupDest ] && backupDest=$toRemove
	printNOK "###########################"
	echo "Remove $toRemove ($type)?"
	printNOK "###########################"
	title="Existing folder for ${APP_NAME}"
	prompt="# "
	options=("Keep $toRemove" "Backup $toRemove in $backupDest" "Remove $toRemove")
	PS3="$prompt"
	select opt in "${options[@]}"; do
		case "$REPLY" in
		1)
			printOK "> Keeping $toRemove"
			break
			;;
		2)
			backupArch ${type} ${toRemove}
			break
			;;
		3)
			rm -rf ${toRemove}
			printNOK "> Oof! $toRemove is gone"
			break
			;;
		*)
			echo "Invalid option. Try another one."
			continue
			;;
		esac
	done
	return $REPLY
}
function confirmDeletePrompts() {
	[ -d ${APP_DIR} ] && deletePrompt $APP_DIR FULL
	[ -d ${APP_RAW_APK_PATH} ] && deletePrompt $APP_RAW_APK_PATH RAW_APK
	[ -d ${APP_PATCHED_APK_PATH} ] && deletePrompt $APP_PATCHED_APK_PATH PATCHED_APK
	[ -d ${APP_RAW_APK_DECOMPILED_JAR_PATH} ] && deletePrompt $APP_RAW_APK_DECOMPILED_JAR_PATH RAW_APK_DECOMPILED_JAR
	[ -d ${APP_RAW_APK_DECOMPILED_SMALI_PATH} ] && deletePrompt $APP_RAW_APK_DECOMPILED_SMALI_PATH RAW_APK_DECOMPILED_SMALI
	setupAppEnv
}
backupArch() {
	# If the file/folder to backup exists
	if [ -d $2 ]; then
		# Creating an old ver of this decompiled folder
		BACKUP_DATE="$(date '+%d%m%H%M%S')"
		BACKUP_FILE_NAME=${APP_NAME}-${BACKUP_DATE}-$1
		BACKUP_FILE="$BACKUPS_PATH/$BACKUP_FILE_NAME"
		printMEH "> Backuping $2 in $BACKUP_FILE"
		mkdir -p ${BACKUP_FILE} && cp -r $2 ${BACKUP_FILE}
		if [ $? -eq 0 ]; then
			printOK "> Backup $BACKUP_LE oké"
		else
			printNOK "\t> Backuping $BACKUP_FILE failed. Re-run or check rights."
			exit -1
		fi
	fi
}
displayUsage() {
	printOK "###########################"
	echo -e "Args"
	printOK "###########################"
	echo -e "-a=app's shortname: whatever name you want to identify your app with (eg. -a=FOO)
-p=https://play.google.com/store/apps/details?id=com.foo.bar -> -p=com.foo.bar
-s=device|emulator|tcpip: source to pull the raw app from. Leaving blank will use the default local folder to load an app's by it's name (./apks/{APP_SHORTNAME}.apk)
-d=device|emulator|tcpip: destination to install a patched app to"
	printOK "###########################"
	echo -e "Flags"
	printOK "###########################"
	echo -e "--dec: decompile. An APK corresponding to the app name needs to be in /apps/{APP_SHORTNAME}/rawPK first.
--rec: recompile. A SMALI folder needs to be in /apps/{APP_SHORTNAME}/smali.
--ow: erase app's structure (1= interactive, 2= force)"

	printOK "###########################"
	echo -e "Examples"
	printOK "###########################"
	echo -e "1. Plug a device or create and launch an AVD (RTFM)
2. [optional] Launch the Play Store app at least once to configure everything
	a. You can also provide a custom APK within /apks/{APP_SHORTNAME}.apk (eg. -a=HO -> /apks/HO.apk can be provided)
3. From any Play Store's app's page, spot the id of the wanted app. eg. https://play.google.com/store/apps/details?id=com.foo.bar&hl=fr -> copy com.foo.bar
4. Run ./patchPK with the desired configuration
	-> For a first time use on any app from a device|emulator|tcpip: ./patchPK -a=FOO -p=com.foo.bar -s=emulator|device|tcpip --dec
5. Tamper with the SMALI in /apps/{APP_SHORTNAME}/smali
6. Recompile + install to a device|emulator|tcpip: ./patchPK -a=FOO -p=com.foo.bar --rec -d=emulator|device|tcpip"
	printOK "###########################"
	exit 1
}
wait_time() {
	local timeToSleep="$1"
	shift
	local wait_seconds="$1:-$timeToSleep"
	shift # 10 seconds as default timeout

	until test $((wait_seconds--)) -eq 0 -o -f "$file"; do sleep 1; done

	((++wait_seconds))
}
APKLogcat() {
	DEVICE=$(adb devices | grep emulator | sed 's/device//g' | sed 's/[[:space:]]*$//g')
	PID=$(adb -s ${DEVICE} shell pidof ${APK_TO_DL})
	printMEH "adb -s $DEVICE logcat --pid=$PID"
	adb -s ${DEVICE} shell ps -A
	adb -s ${DEVICE} logcat --pid=${PID}
}
