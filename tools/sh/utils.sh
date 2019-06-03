#!/bin/bash
# Prompt colors
printOK() {
	green="\x1B[32m"
	echo -e "${green}$1\x1B[m"
}
printNOK() {
	red="\x1B[31m"
	echo -e "${red}$1\x1B[m"
}
printMEH() {
	yellow="\x1B[33m"
	echo -e "${yellow}$1\x1B[m"
}
# Delete existing architecture prompts
function confirmDeletePrompts(){
	if [ -d ${APP_DIR} ]
	then   # for file "if [-f /home/rama/file]"
		title="Existing folder for ${APP_NAME}"
		prompt="->"
		options=("Keep" "Remove" "Backup")

		printMEH "- $title"
		PS3="$prompt "
		select opt in "${options[@]}"; do 
			case "${REPLY}" in
			# Keeping the existing arch
			1 ) return; break;;
			# Removing existing arch - another prompt, just to be sure..
			2 ) break;;
			3 ) backupArch FULL ${APP_DIR} ${APPS_PATH} ; break;;
			# Meh
			*) echo "Invalid option. Try another one.";continue;;
			esac
		done
		if [ -d ${APP_DIR} ]
		then
		printNOK "###########################"
		echo "Remove ${APP_DIR}?"
		printNOK "###########################"
		prompt="-> "
		options=("Yes, remove this folder" "Nope, nevermind")
		PS3="$prompt"
		select opt in "${options[@]}"; do 
			case "${REPLY}" in
				1 ) printNOK "Oof! ${APP_DIR} is gone"; rm -r ${APP_DIR};break;;
				2 ) printOK "Keeping them, was so close!"; break;;
				*) echo "Invalid option. Try another one.";continue;;
			esac
		done
		printNOK "###########################"
		echo "Remove ${RAW_APK}?"
		printNOK "###########################"
		prompt="-> "
		options=("Yes, remove this file" "Nope, nevermind")
		PS3="$prompt"
		select opt in "${options[@]}"; do 
			case "${REPLY}" in
				1 ) printNOK "Oof! RAW_APK is gone"; rm ${RAW_APK}; break;;
				2 ) printOK "Keeping them, was so close!"; break;;
				*) echo "Invalid option. Try another one.";continue;;
			esac
		done
		fi
	else echo "First try for ${APP_NAME}!";
	fi
}
backupArch(){
	# If a type of backup is specified: SMALI, JAR, FULL, APK..
	if [ -d $2 ]; then 
		# Creating an old ver of this decompiled folder
		BACKUP_DATE="$(date '+%d%m%H%M%S')"
		BACKUP_FILE_NAME=${APP_NAME}-${BACKUP_DATE}-old-$1
		# If a destination is set, use it
		if [ ! -z $3 ]; then BACKUP_FILE="${3}/${BACKUP_FILE_NAME}"; 
		else BACKUP_FILE="${APP_DIR}/${BACKUP_FILE_NAME}"; fi;
		mkdir -p ${BACKUP_FILE}/ && mv $2 ${BACKUP_FILE}
		if [ $? -eq 0 ]; then printOK "\t> Backup ${BACKUP_FILE} oké"
		else printNOK "\t> Backuping ${BACKUP_FILE} failed. Re-run or check rights."; exit -1; fi
	fi
}
displayUsage(){
printNOK "###########################"
printNOK "###########################"
echo -e "Used to load, decompile and recompile any APK from the Google Play Store, loaded from an emulator or a device or a local folder."
printOK "###########################"
echo -e "Process";
printOK "###########################"
echo -e "1. Plug the device (with dev options activated and/or rooted) or create and launch a Pixel 2 emulator (RTFM)
2. Launch the Play Store app at least once to configure everything (/!\/!\ Make sure not to be behind any proxy for it to load correctly /!\/!\)
3. From any Play Store's app's page, spot the id of the wanted app. eg. https://play.google.com/store/apps/details?id=com.foo.bar&hl=fr -> copy com.foo.bar
4. Run ./rPath with the desired configuration.
	-> For a first time use on any app: ./rPath -a=APP_NAME -s=emulator|device
	-> + Decompile: ./rPath -a=APP_NAME -s=emulator|device --dec=true
	-> + Recompile: ./rPath -a=APP_NAME -s=emulator|device --rec=true
	-> + Patch: ./rPath -a=APP_NAME -s=emulator|device --patch=true
	-> + Install: ./rPath -a=APP_NAME -s=emulator|device -d=emulator|device

	-> All in one: ./rPath -a=APP_NAME -s=emulator --dec=true --patch=true --rec=true -d=emulator\n"
printOK "###########################"
echo -e "Flags";
printOK "###########################"
echo -e "-a=name of the application (short names: CA, LBP, BPOP..) used within the process [mandatory]
	-> rPath needs an app name to work with: shortname of the APK (eg. WHATTSAPP, FACEBOOK, SNAPCHAT): no space, nothing. It's used to ease the manipulation of raw APKs and tampered AKs.
-p=id of the Google Store package to be tampered with (go to the Google Play store, search for an app and open it's page and within the URL: id=com.app.foo -> p=com.app.foo)
-d=device|emulator: destination to install the tampered app: [a package name is required in order to install the tampered app]
-s=device|emulator: source to pull the raw app from: [a package name is required in order to pull the raw app]. Leaving blank will use the default local folder /apks/
	-> If -s is not specified, rPatch will load the APP_NAME.apk within ./apks/ (eg. FACEBOOK.apk, WHATSAPP.apk, SNAPCHAT.apk)
    -> If -s is specified, rPatch will need a package name in order to work (see -p flag)
-r=true|all:
	- step: if, during ANY step of the process (raw APK download, decompile, recompile), an output exists for the current process, remove this output. (/apps/appDir/(smali|jar|rawPK|patchedPK))
	- all: erase the whole app dir + it's raw APK. (/apps/appDir)
- Process:
--dec: decompile. An APK corresponding to the app name needs to be in /apks/ first.
--patch: patch. A SMALI folder needs to be in /apps/app/smali.
--rec: recompile. A SMALI folder needs to be in /apps/app/smali.";
printNOK "###########################"
printNOK "###########################"
exit 1; 
}
wait_time() {
  local timeToSleep="$1"; shift
  local wait_seconds="${1:-$timeToSleep}"; shift # 10 seconds as default timeout

  until test $((wait_seconds--)) -eq 0 -o -f "$file" ; do sleep 1; done

  ((++wait_seconds))
}
APKLogcat(){
	DEVICE=$(adb devices | grep emulator | sed 's/device//g' | sed 's/[[:space:]]*$//g')
    PID=$(adb -s ${DEVICE} shell pidof ${APK_TO_DL})
	printMEH "adb -s ${DEVICE} logcat --pid=${PID}"
	adb -s ${DEVICE} shell ps -A
	adb -s ${DEVICE} logcat --pid=${PID}
}