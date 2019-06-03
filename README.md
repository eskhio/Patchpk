# PatchPK

PatchPK is a usefull tool used to automate the basic process of decompiling and patching an Android application.

# File structure:
```
- apks <- APK to play with are stored here
    - ...apk
    - ...apk
- apps <- Apps that we're tampering with are stored here
    - ..
        - rawPK <- A copy of the app's raw APK
        - patchedPK <- The tampered APK is stored here at the end of the process
        - smali <- The raw APK's smali code
        - java <- The tampered APK JAR file
    _ ..
- tools <- Tools used
    - js
    - sh
    - utils
```
# Usage

## Easy
Load any app from an emulator or a device's play store onto rPatch file structure
```
./rPatch -a=APP_NAME (-s=emulator|device) 
```
#### Decompile it
```
./rPatch -a=APP_NAME -s=emulator|device --dec=true
```
#### Patch it
```
./rPatch -a=APP_NAME -s=emulator|device --patch=true 
```
#### Recompile it
```
./rPatch -a=APP_NAME -s=emulator|device --rec=true
```
#### Install it
```
./rPatch -a=APP_NAME -s=emulator|device -d=emulator|device
```
#### All in one on an APK in /apks/:

No -s specified. This can be used to tamper an APK loaded before. Just put in /apks/APP_NAME.apk and rPatch will work on it with
```
./rPatch -a=CA -p=fr.creditagricole.androidapp --dec=true --patch=true --rec=true -d=emulator
```
## Advanced usage

#### All in one + bypassing if a step output is already there:

If any of step's process (decompile, recompile or else) has already been done on -a=APP_NAME, we skip the current step.
```
./rPatch -a=CA -s=emulator -p=fr.creditagricole.androidapp --dec=true --patch=true --rec=true -d=emulator
```
#### All in one + remove existing app folder:

If any of step's process (decompile, recompile or else) has already been done on -a=APP_NAME, we can erase the whole app dir in order to get a fresh install: you can erase the app dir + the raw APK stored in /apks/ (APP_NAME.apk).
```
./rPatch -a=CA -s=emulator -p=fr.creditagricole.androidapp --dec=true --patch=true --rec=true -d=emulator -r=all
```
	
will remove the /apps/CA folder and then decompile, patch and recompile CA.apk (crafted from fr.creditagricole.androidapp, from the emulator).
	
#### All in one + remove existing step output:

If any of step's process (decompile, recompile or else) has already been done on -a=APP_NAME, we can erase the whole app dir in order to get a fresh install: you can erase the app dir + the raw APK stored in /apks/ (APP_NAME.apk).
```
./rPatch -a=CA -s=emulator -p=fr.creditagricole.androidapp --dec=true --patch=true --rec=true -d=emulator -r=all
```
	
will decompile, patch and recompile CA.apk (crafted from fr.creditagricole.androidapp, from the emulator) and remove any spotted steps' output (/smali/, /jar/ or else)
	
#### All in one + backup existing:

If the process has already been done on -a=APP_NAME, we can backup the whole process outputs, in order to keep the work done.

```
./rPatch -a=CA -s=emulator -p=fr.creditagricole.androidapp --dec=true --patch=true --rec=true -d=emulator -b=true
```

will decompile, patch and recompile CA.apk (crafted from fr.creditagricole.androidapp, from the emulator) and backup any spotted steps' output (/smali/, /jar/ or else)
	
## Flags: 
```
-a=name of the application (short names: CA, LBP, BPOP..) used within the process [mandatory]
    -> rPath needs an app name to work with: shortname of the APK (eg. WHATTSAPP, FACEBOOK, SNAPCHAT): no space, nothing. It's used to ease the manipulation of raw APKs and tampered AKs.
-p=id of the Google Store package to be tampered with (go to the Google Play store, search for an app and open it's page and within the URL: id=com.app.foo -> p=com.app.foo)
-d=device|emulator: destination to install the tampered app: [a package name is required in order to install the tampered app]
-s=device|emulator: source to pull the raw app from: [a package name is required in order to pull the raw app]. Leaving blank will use the default local folder /apks/
    -> If -s is not specified, rPatch will load the APP_NAME.apk within ./apks/ (eg. FACEBOOK.apk, WHATSAPP.apk, SNAPCHAT.apk)
    -> If -s is specified, rPatch will need a package name in order to work (see -p flag)
-r=true|all:
	- true: if, during ANY step of the process (raw APK download, decompile, recompile), an output exists for the current process, remove this output. (/apps/appDir/(smali|jar|rawPK|patchedPK))
	- all: erase the whole app dir + it's raw APK. (/apps/appDir)
--dec: decompile. An APK corresponding to the app name needs to be in /apks/ first.
--patch: patch. A SMALI folder needs to be in /apps/app/smali. / ! \ Mostly unstable for now / ! \
--rec: recompile. A SMALI folder needs to be in /apps/app/smali.
```
# Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.
