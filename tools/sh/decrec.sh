#!/bin/bash
decToSmali(){
	echo -e "##################################"
	echo -e "Decompiling to SMALI"
	echo -e "##################################"
	# Exporting the APK's content to the conf decompiled path
	printMEH "- Decompiling ${APK_CLEANED} to ${DECOMPILED_APP_PATH}/"

	# No APK to decompile within /app/rawPK
	if [ ! -f ${APK_CLEANED} ]; then printNOK "\t> We don't have any APK for ${APP_NAME}.."; exit -1; fi
	# A SMALI folder is already here
	if [ -d ${DECOMPILED_APP_PATH} ]; then 
		printOK "\t> We already have a decompiled SMALI folder for ${APP_NAME}."
		# Backup
		if [ ${BACKUP_EXISTING} -eq 1 ]; then printMEH "\t> Backuping existing.."; backupArch SMALI ${DECOMPILED_APP_PATH};
		# Bypass decompiling and using the existing SMALI folder
		elif [ ${BACKUP_EXISTING} -eq 2 ]; then printOK "\t> Working on "${DECOMPILED_APP_PATH}; return
		# Delete existing and refresh the SMALI
		elif [ ${DELETE_EXISTING} -eq 1 ]; then printNOK "\t> Deleting existing.. "; rm -r ${DECOMPILED_APP_PATH}; fi;
		printMEH "- Decompiling ${APK_CLEANED} to ${DECOMPILED_APP_PATH}/"
	fi
	# Decompile app/rawPK/.apk towards app/smali/
	${APK_TOOL_PATH} d ${APK_CLEANED} -o ${DECOMPILED_APP_PATH} -f -r &> ${DECOMPILED_APP_PATH}.apktoold.log
	if [ $? -eq 0 ]; then printOK "\t> Decompiled ${APP_NAME}.apk in ${DECOMPILED_APP_PATH} oké"; 
	else printNOK "\t> Decompiled ${APP_NAME}.apk in ${DECOMPILED_APP_PATH} failed. Re-run or check fs/sh rights."; exit -1; fi
}
decToJar(){
	echo -e "##################################"
	echo -e "Decompiling to JAR"
	echo -e "##################################"
    printMEH "- Decompiling ${PATCHED_APK} to ${CLEANED_APK_JAR_EXPORT}.."
	
	# No APK to decompile within /app/patchedPK
	if [ ! -f ${PATCHED_APK} ]; then printNOK "\t> We don't have any source APK for ${PATCHED_APK}."; exit -1; fi
	# A java folder is already here
	if [ -f ${CLEANED_APK_JAR_EXPORT} ]; 	then 
		printOK "\t> We already have a decompiled JAR folder for ${APP_NAME}: ${CLEANED_APK_JAR_EXPORT}."
		# Backup
		if [ ${BACKUP_EXISTING} -eq 1 ];  then printMEH "\t> Backuping existing.."; backupArch JAR ${CLEANED_APK_EXTRACTED_JAR_PATH}; 
		# Bypass decompiling and using the existing java folder
		elif [ ${BACKUP_EXISTING} -eq 2 ]; then printOK "\t> Working on "${CLEANED_APK_JAR_EXPORT}; return
		# Delete existing and refresh the JAR
		elif [ ${DELETE_EXISTING} -eq 1 ]; then printNOK "\t> Deleting existing.. "; rm -r ${CLEANED_APK_JAR_EXPORT}; fi;
		printMEH "- Decompiling ${PATCHED_APK} to ${CLEANED_APK_JAR_EXPORT}.."
	fi
	# Decompile app/patchedPK/.apk towards app/java/
	${D2J} ${PATCHED_APK} -o ${CLEANED_APK_JAR_EXPORT} > /dev/null
	if [ $? -eq 0 ]; then printOK "\t> Decompiled ${CLEANED_APK_JAR_EXPORT} in ${CLEANED_APK_JAR_EXPORT} oké";
	else printNOK "\t> Decompiled ${PATCHED_APK} in ${CLEANED_APK_JAR_EXPORT} failed. Re-run or check fs/sh rights."; exit -1; fi
}
recompile(){
	echo -e "##################################"
	echo -e "Recompiling"
	echo -e "##################################"
	printMEH "- Recompiling ${DECOMPILED_APP_PATH} to ${PATCHED_APK}" 
	
	# If we don't have any SMALI folder
    if [ ! -d ${DECOMPILED_APP_PATH} ]; then printNOK "\t> We don't have any decompiled folder (${DECOMPILED_APP_PATH}) file for ${APP_NAME}. Run --dec=true first."; exit 1; fi;
	# If we already have a patched APK from a SMALI recompilation
	if [ -f ${PATCHED_APK} ]; then 
		printOK "\t> We already have a recompiled APK: ${PATCHED_APK}"
		# Backup
		if [ ${BACKUP_EXISTING} -eq 1 ]; then printMEH "\t> Backuping existing.."; backupArch APK {DECOMPILED_APP_PATH};
		# Bypass recompiling and using the existing patched APK folder
		elif [ ${BACKUP_EXISTING} -eq 2 ]; then printOK "\t> Working with ${PATCHED_APK}"; return
		# Delete existing and refresh the APK
		elif [ ${DELETE_EXISTING} -eq 1 ]; then printNOK "\t> Deleting existing.. "; rm -r ${PATCHED_APK}; fi;
		printMEH "- Recompiling ${DECOMPILED_APP_PATH} to ${PATCHED_APK}" 
	fi
    # Rebuilding as the patched apk (/patchedPK)
	${APK_TOOL_PATH} b ${DECOMPILED_APP_PATH} -o ${PATCHED_APK} &> ${DECOMPILED_APP_PATH}.apktoold.log
	if [ $? -eq 0 ]; then printOK "\t> Patched APK created @ ${PATCHED_APK}"; 
	else printNOK "\t> Recompile ${DECOMPILED_APP_PATH} failed. Re-run or check fs/sh rights."; exit -1; fi
	# Making a copy as tmp.apk, if success
    cp ${PATCHED_APK} ${TEMP_APK}
}
signAPK(){
	echo -e "##################################"
	echo -e "APK signing"
	echo -e "##################################"
	printMEH "- Signin ${PATCHED_APK} from ${TEMP_APK}.."
	echo $JKS_PASSWORD | ${APK_SIGN} --ks $JKS_PATH --out ${PATCHED_APK} ${TEMP_APK} > /dev/null
	if [ $? -eq 0 ]; then printOK "\t> Signin: ${PATCHED_APK} (+tmp.apk) oké!";
	else printNOK "\t> Signing ${PATCHED_APK} failed. Re-run or check fs/sh rights."; exit -1; fi
}
