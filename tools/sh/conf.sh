# apktool
APK_TOOL_PATH=${TOOLS_PATH}/utils/apktool/apktool

# dex2jar
D2J="$TOOLS_PATH/utils/dex2jar-2.2/d2j-dex2jar.sh"

setupAppEnv() {
	echo -e "##################################"
	echo -e "Setting up new app env"
	echo -e "##################################"
	
	# App info
	printOK "- App name: $APP_NAME"
	# Format checking and stuff
	[ -z "$APP_NAME" ] && printNOK "- No app supplied" && exit 1
	[[ ! ${APP_NAME} =~ (^[a-zA-Z]{2,})$ ]] && printNOK "- App has to be ^([a-zA-Z]2,)$" && exit 1

	printOK "- APKs path: $APKS_PATH"
	APK_SOURCE_PATH=${APKS_PATH}

	# Vanilla APK target
	APP_DIR=$APPS_PATH/$APP_NAME
	APP_RAW_APK_PATH=$APP_DIR/rawPK
	APP_RAW_APK=$APP_RAW_APK_PATH/$APP_NAME.apk
	APP_RAW_APK_DECOMPILED_JAR_PATH=$APP_RAW_APK_PATH/java
	APP_RAW_APK_DECOMPILED_JAR=$APP_RAW_APK_DECOMPILED_JAR_PATH/$APP_NAME.jar
	APP_RAW_APK_DECOMPILED_JAR_LOG=$APP_RAW_APK_PATH/$APP_NAME.d2j.log
	APP_RAW_APK_DECOMPILED_SMALI_PATH=$APP_RAW_APK_PATH/smali
	APP_RAW_APK_DECOMPILED_SMALI_LOG=$APP_RAW_APK_PATH/$APP_NAME.smali.log
	
	# Patched APK target
	APP_PATCHED_APK_PATH=$APP_DIR/patchedPK
	APP_PATCHED_APK=$APP_PATCHED_APK_PATH/$APP_NAME.apk
	APP_PATCHED_APK_DECOMPILED_JAR_PATH=$APP_PATCHED_APK_PATH/java
	APP_PATCHED_APK_DECOMPILED_JAR=$APP_PATCHED_APK_DECOMPILED_JAR_PATH/$APP_NAME.jar
	APP_PATCHED_APK_DECOMPILED_JAR_LOG=$APP_RAW_APK_PATH/$APP_NAME.d2j.log
	APP_PATCHED_APK_DECOMPILED_SMALI_PATH=$APP_PATCHED_APK_PATH/smali
	APP_PATCHED_APK_DECOMPILED_SMALI_LOG=$APP_PATCHED_APK_PATH/$APP_NAME.smali.log

	if [[ $LEVEL == 1 ]]; then
		printNOK "- Overwrite mode: interactive"
		LEVEL=0
		confirmDeletePrompts
	elif [[ $LEVEL == 2 ]]; then 
		printNOK "- Overwrite mode: force"
		OVERWRITE_EXISTING_OUTPUT=1
	else printOK "- Overwrite mode: skip if output already exists"
	fi

	# If a destination or a source is specified, we need to have a package name specified
	if [ ! -z $SOURCE ]; then
		[ ! $DESTINATION ] && DESTINATION=$SOURCE; 
		if [ ! -z $APK_TO_DL ]; then printOK "\t> Google play package: $APK_TO_DL"
		else printNOK "- No package specified (-s is $SOURCE, we need to find the app's package within)"; exit 1; fi
	fi

	# Creating app's structure
	if [ ! -d $APP_PATCHED_APK_PATH ]; then
		printMEH "> Creating $APP_PATCHED_APK_PATH.."
		mkdir -p $APP_PATCHED_APK_PATH
		[ $? -eq 0 ] && printOK "\t> Oké"
	fi
	if [ ! -d $APP_RAW_APK_PATH ]; then
		printMEH "> Creating $APP_RAW_APK_PATH.."
		mkdir -p $APP_RAW_APK_PATH
		[ $? -eq 0 ] && printOK "\t> Oké"
	fi
	printOK "- $APP_RAW_APK_PATH + $APP_PATCHED_APK_PATH ready"

	# If a destination or a source is specified, we need to have a package name specified
	if [ ! -z $SOURCE ]; then
		[ ! $DESTINATION ] && DESTINATION=$SOURCE; 
		if [ ! -z $APK_TO_DL ]; then printOK "\t> Google play package: $APK_TO_DL"
		else printNOK "- No package specified (-s is $SOURCE, we need to find the app's package within)"; exit 1; fi
	fi

	# Copying possible previously downloaded apks for this app from /apks/
	if [ ! $OVERWRITE_EXISTING_OUTPUT ]; then 
		RAW_APK=${APKS_PATH}/${APP_NAME}.apk
		if [ -f $RAW_APK ] && [ ! -f $APP_RAW_APK ]; then
			printMEH "> Copying existing raw app's ($RAW_APK) to $APP_RAW_APK_PATH (--ow=2 to overwrite and use a new APK from source -s)"
			cp $RAW_APK $APP_RAW_APK_PATH
			[ $? -eq 0 ] && printOK "\t> Oké"; 
		fi
	fi
}
setupAppSource(){
	echo -e "##################################"
	echo -e "Setting up source device ($SOURCE)"
	echo -e "##################################"
	# Working with real device source
	if [ "$SOURCE" = "device" ]; then
		ADB_SOURCE_DEVICE=$(adb -d get-serialno > /dev/null 2>&1)
		XTAP="1000"
		YTAP="1000"
	# Working with TCPIP devices
	elif [ "$SOURCE" = "tcpip" ]; then
		ADB_SOURCE_DEVICE=$(adb -e get-serialno > /dev/null 2>&1)
		XTAP="1000"
		YTAP="1000"
	# Working with AVD source
	elif [ "$SOURCE" = "emulator" ]; then
		ADB_SOURCE_DEVICE=$(adb devices | grep emulator | sed 's/device//g' | sed 's/[[:space:]]*$//g')
		XTAP="550"
		YTAP="750"
	fi
	# Checking the result
	if [ ! -z ${ADB_SOURCE_DEVICE} ]; then printOK "- Source: $ADB_SOURCE_DEVICE"; else printNOK "- No source device spotted"; exit 1; fi
}
setupAppDestination(){
	echo -e "##################################"
	echo -e "Setting destination device"
	echo -e "##################################"
	# Working with real device destination
	if [ "$DESTINATION" = "device" ]; then
		ADB_DESTINATION_DEVICE=$(adb -d get-serialno)
		XTAP="1000"
		YTAP="1000"
	# Working with TCPIP devices
	elif [ "$DESTINATION" = "tcpip" ]; then
		ADB_DESTINATION_DEVICE=$(adb -e get-serialno)
		XTAP="1000"
		YTAP="1000"
	# Working with AVD destination
	elif [ "$DESTINATION" = "emulator" ]; then
		ADB_DESTINATION_DEVICE=$(adb devices | grep emulator | sed 's/device//g' | sed 's/[[:space:]]*$//g')
		XTAP="550"
		YTAP="750"
	fi
	# Checking the result
	if [ ! -z ${ADB_DESTINATION_DEVICE} ]; then printOK "- Destination: $ADB_DESTINATION_DEVICE"; else printNOK "- No destination device spotted"; exit 1; fi
}

for i in "$@"; do
	case $i in
		# Decompile the APK
		--dec)
			DEC=1
			shift
		;;
		# Recompile the app
		--rec)
			REC=1
			shift
		;;
		# Backup app's folder if exists
		--backup)
			BACKUP_EXISTING_OUTPUT=1
			shift
		;;
		# Remove app's folder (interactive)
		--ow=*)
			LEVEL="${i#*=}"
			shift
		;;
		--help)
			displayUsage
			shift
		;;
		# App info
		-a=* | --appname=*)
			APP_NAME="${i#*=}"
			shift
		;;
		# Source to find the APK from
		-s=* | --source=*)
			SOURCE="${i#*=}"
			setupAppSource
			shift
		;;
		# Destination the send the APK to
		-d=* | --destination=*)
			DESTINATION="${i#*=}"
			setupAppDestination
			shift
		;;
		# App's google play package
		-p=* | --package=*)
			APK_TO_DL="${i#*=}"
			shift
		;;
		--default)
			DEFAULT=exit 1
			shift
		;;
		*) ;;
	esac
done
setupAppEnv
