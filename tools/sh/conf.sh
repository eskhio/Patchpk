#!/bin/bash
echo -e "\n##################################"
echo "Configuration"
echo -e "##################################"

# apktool
APK_TOOL_PATH=${TOOLS_PATH}/utils/apktool/apktool

# dex2jar
D2J="${TOOLS_PATH}/utils/dex2jar-2.0/d2j-dex2jar.sh"
# Android APK signer
ANDROID_SDK='28.0.3'
APK_SIGN="${HOME}/Library/Android/sdk/build-tools/${ANDROID_SDK}/apksigner sign"
JKS_PATH="${TOOLS_PATH}/utils/sign/fake.jks"
JKS_PASSWORD='azerty123'

# Backup and wipe default config: bypass if step has been done (/smali/, /jar/ or else)
BACKUP_EXISTING=2
DELETE_EXISTING=0

for i in "$@"; do
case $i in
	# App info
	-a=* | --appname=*)
		
		APP_NAME="${i#*=}"
		
		# App reverse structure depending on the app name
		APP_DIR=${APPS_PATH}/${APP_NAME}
		
		# Vanilla APK target
		RAW_APK=${APKS_PATH}/${APP_NAME}.apk
		RAW_APK_CLEANED_PATH="${APP_DIR}/rawPK"

		# Vanilla APK target will be decompiiled in
		DECOMPILED_APP_PATH="${APP_DIR}/smali"

		# Patched APK target
		APK_CLEANED="${RAW_APK_CLEANED_PATH}/${APP_NAME}.apk"
		PATCHED_APK_PATH="${APP_DIR}/patchedPK"
		PATCHED_APK="${PATCHED_APK_PATH}/${APP_NAME}.apk"
		TEMP_APK="${PATCHED_APK_PATH}/tmp.apk"

		# Java structure
		CLEANED_APK_EXTRACTED_JAR_PATH="${APP_DIR}/java"
		CLEANED_APK_JAR_EXPORT="${CLEANED_APK_EXTRACTED_JAR_PATH}/${APP_NAME}.jar"
		shift 
	;;
	# Backup app's folder if exists
	-b=* | --backup=*)
		BACKUP_EXISTING=1
		shift 
	;;
	# Remove ADB device SN
	-d=* | --destination=*)
		DESTINATION="${i#*=}"
		# Working with real device destination
		if [ "${DESTINATION}" = "device" ]; then
			ADB_DESTINATION_DEVICE=$(adb -d get-serialno)
			XTAP="1000"
			YTAP="1000"
		# Working with AVD destination
		elif [ "${DESTINATION}" = "emulator" ]; 
			then ADB_DESTINATION_DEVICE=$(adb devices | grep emulator | sed 's/device//g' | sed 's/[[:space:]]*$//g')
			XTAP="550"
			YTAP="750"
		fi;
		# Checking the result
		if [ ! -z ${ADB_DESTINATION_DEVICE} ]; then printOK "- Destination device: ${ADB_DESTINATION_DEVICE}"; else printNOK "- No destination device spotted"; exit 1; fi;
		shift 
	;;
	# Package to DL
	-p=* | --package=*)
		APK_TO_DL="${i#*=}"
		shift 
	;;
	# Remove app's folder if exists
	-r=* | --removexisting=*)
		BACKUP_EXISTING=0
		DELETE_EXISTING="${i#*=}"
		# If the user wants to erase everything about this app, let's be sure
		if [ ${DELETE_EXISTING} = "all" ]; then confirmDeletePrompts; fi
		DELETE_EXISTING=1
		shift 
	;;
	# Source to find the APK
	-s=* | --source=*)
		APK_SOURCE_PATH="${i#*=}"
		SOURCE="${i#*=}"
		# Working with real device source
		if [ "${SOURCE}" = "device" ]; then
			ADB_SOURCE_DEVICE=$(adb -d get-serialno)
			XTAP="1000"
			YTAP="1000"
		# Working with AVD source
		elif [ "${SOURCE}" = "emulator" ]; 
			then 
			ADB_SOURCE_DEVICE=$(adb devices | grep emulator | sed 's/device//g' | sed 's/[[:space:]]*$//g')
			XTAP="550"
			YTAP="750"
		fi;
		# Checking the result
		if [ ! -z ${ADB_SOURCE_DEVICE} ]; then printOK "- Source device: ${ADB_SOURCE_DEVICE}"; else printNOK "- No source device spotted"; exit 1; fi;
		shift 
	;;
	# Decompile the APK
	--dec=*)
		DEC="${i#*=}"
		shift 
	;;
	# Patch the app
	--patch=*)
		PATCH="${i#*=}"
		shift 
	;;
	# Recompile the app
	--rec=*)
		REC="${i#*=}"
		shift 
	;;
	--default)
		DEFAULT=exit 1
		shift # past argument with no value
	;;
	*) ;;
	
esac
done

handleGeneralConfiguration(){
	# Format checking and stuff
	if [ -z "${APP_NAME}" ]; then
		printNOK "- No app supplied"
		exit 1
	fi
	if [[ ! ${APP_NAME} =~ (^[a-zA-Z]{2,})$ ]]; then
		printNOK "- App has to be ^([a-zA-Z]{2,})$"
		exit 1
	fi
}
handleAPKSource(){
	# Working with source folder given by user
	if [ ! -z ${APK_SOURCE_PATH} ]; then
		printOK "- APK source folder: ${SOURCE}/data/app/"
	else
		# Working with default source folder (${HOME}/Documents/Reverse/tmpsd/apks)
		printMEH "- Local APK: no source folder supplied"
		printOK "\t> defaulting to ${APKS_PATH}"
		APK_SOURCE_PATH=${APKS_PATH}
	fi
	# If a destination or a source is specified, we need to have a package name specified
	if [ ! -z "${DESTINATION}" ] || [ ! -z "${SOURCE}" ]; then
		if [ ! -z "${APK_TO_DL}" ]; then
			printOK "- Google play package: ${APK_TO_DL}"
		else
			printNOK "- No package specified"
			exit 1
		fi
	fi
}
setupAppEnv() {
	echo -e "##################################"
	echo -e "Setting up new app env"
	echo -e "##################################"
	printMEH "- Preparing the file structure for ${APP_NAME}"
	if [ ! -d ${PATCHED_APK_PATH} ]; then
		printOK "Already setted up 1/2"
		mkdir -p ${PATCHED_APK_PATH}
		if [ ! -d ${RAW_APK_CLEANED_PATH} ]; then
			printOK "Already setted up 2/2"
			mkdir -p ${RAW_APK_CLEANED_PATH}
		fi
	fi

	mkdir -p ${APP_DIR}
	mkdir -p ${APKS_PATH}
	
	printOK "\t> Done preparing ${RAW_APK_CLEANED_PATH} and ${PATCHED_APK_PATH}!"
}

# Handling general configuration: app name checking for it to be fine
handleGeneralConfiguration
# Handling APK source, specified by the user or not (local or device/AVD)
handleAPKSource
