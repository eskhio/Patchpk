#!/bin/bash
decToSMALI() {
	echo -e "##################################"
	echo -e "Decompiling to SMALI"
	echo -e "##################################"
	checkExpectedStructure
	[ -f $APP_PATCHED_APK ] && decAPKToSMALI $APP_PATCHED_APK $APP_PATCHED_APK_DECOMPILED_SMALI_PATH
	[ -f $APP_RAW_APK ] && decAPKToSMALI $APP_RAW_APK $APP_RAW_APK_DECOMPILED_SMALI_PATH
}
decToJAR() {
	echo -e "##################################"
	echo -e "Decompiling to JAR"
	echo -e "##################################"
	checkExpectedStructure
	[ -f $APP_PATCHED_APK ] && decAPKToJAR $APP_PATCHED_APK $APP_PATCHED_APK_DECOMPILED_JAR
	[ -f $APP_RAW_APK ] && decAPKToJAR $APP_RAW_APK $APP_RAW_APK_DECOMPILED_JAR
}
decAPKToSMALI() {
	apkin=$1
	smaliout=$2
	backupOrDelete $smaliout RAW_APK_DECOMPILED_SMALI && return
	printMEH "> Decompiling $apkin to $smaliout/"
	$APK_TOOL_PATH d $apkin -o $smaliout -f -r >$APP_PATCHED_APK_DECOMPILED_SMALI_LOG 2>&1
	if
		[ $? -eq 0 ] &
		[ -d $smaliout ]
	then
		printOK "\t> Decompiled raw $apkin in $smaliout oké"
	else printNOK "\t> Decompiled raw $apkin in $smaliout failed. Check $smaliout.log"; fi
}
decAPKToJAR() {
	apkin=$1
	jarout=$2
	backupOrDelete $jarout RAW_APK_DECOMPILED_JAR && return
	printMEH "> Decompiling $apkin to $jarout"
	$D2J $apkin -o $jarout >$APP_PATCHED_APK_DECOMPILED_JAR_LOG 2>&1
	if
		[ $? -eq 0 ] &
		[ -f $jarout ]
	then
		printOK "\t> Decompiled $apkin in $jarout oké"
	else printNOK "\t> Decompiled $apkin in $jarout failed. Check $APP_DIR.d2j.log"; fi
}
recAPKFromSMALI() {
	echo -e "##################################"
	echo -e "Recompiling"
	echo -e "##################################"
	[ ! -d $APP_RAW_APK_DECOMPILED_SMALI_PATH ] && printNOK "\t> No $APP_RAW_APK_DECOMPILED_SMALI_PATH for $APP_NAME (run --dec)" && return
	if backupOrDelete $APP_PATCHED_APK_PATH PATCHED_APK 1; then return; fi
	printMEH "- Recompiling $APP_RAW_APK_DECOMPILED_SMALI_PATH to $APP_PATCHED_APK"
	$APK_TOOL_PATH b $APP_RAW_APK_DECOMPILED_SMALI_PATH -o $APP_PATCHED_APK >$APP_PATCHED_APK_DECOMPILED_SMALI_LOG 2>&1
	if
		[ $? -eq 0 ] &
		[ -f $APP_PATCHED_APK ]
	then
		printOK "\t> Patched APK created @ $APP_PATCHED_APK"
	else printNOK "\t> Recompile $APP_RAW_APK_DECOMPILED_SMALI_PATH failed. Check $APP_PATCHED_APK_DECOMPILED_SMALI_LOG.log"; fi
}
backupOrDelete() {
	in=$1
	type=$2
	recreate=$3

	if [ ! -z $BACKUP_EXISTING_OUTPUT ]; then
		printMEH "\t> Backup existing $in for $type"
		backupArch $type $in $APP_DIR
	elif [[ (-f $in || -d $in) && -z $OVERWRITE_EXISTING_OUTPUT ]]; then
		printNOK "> We already have an output file for $type ($in) for $APP_NAME"
		printOK "\t> Skipping (--ow=1|2 to overwrite)"
		return 0
	elif [ ! -z $OVERWRITE_EXISTING_OUTPUT ]; then
		printNOK "> We already have an output file for $type ($in) for $APP_NAME + --ow=2, overwriting"
		rm -rf $in
		[ recreate ] && mkdir $in
	fi
	return 1
}
checkExpectedStructure() {
	[ ! -f $APP_PATCHED_APK ] &&
		printNOK "> We don't have any patched APK ($APP_PATCHED_APK) for $APP_NAME (run --rec)" &&
		printOK "\t> Skipping (--rec to create)"
	[ ! -f $APP_RAW_APK ] &&
		printNOK "> We don't have any raw APK ($APP_RAW_APK) for $APP_NAME (run -s=device|emulator|tcpip or put $APP_NAME.apk into $APKS_PATH)" &&
		printOK "\t> Skipping (--dec --ow=1|2 to overwrite)"
}
