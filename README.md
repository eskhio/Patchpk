# PatchPK
PatchPK is a useful tool used to automate the basic process of downloading an app's packages from a device|emulator|tcpip and decompiling it/them to SMALI and JAR, easing the process of tampering with them.

## Usage with a device
Only if `-s=device|emulator|tcpip` is specified
1. Plug a device or create and launch an AVD or connect to a TCPIP device (RTFM)
2. Launch the play store at least once on the to desired device
3. From any play store's app's page, spot the id of the wanted app. eg. https://play.google.com/store/apps/details?id=com.foo.bar&hl=fr -> `-p=com.foo.bar`
4. Run `./patchPK` with the desired configuration
```
./patchPK -a=FOO -p=com.foo.bar -s=emulator|device|tcpip --dec
```
5. **[optional]** Tamper with the SMALI in `/apps/{APP_SHORTNAME}/smali`
6. Recompile + install
```
./patchPK -a=FOO -p=com.foo.bar -d=emulator|device|tcpip --rec
```
## Usage without a device
1. Provide a custom APK in `/apks/{APP_SHORTNAME}.apk` (eg. `-a=HO` -> `/apks/HO.apk`, only if no source is not specified)
2. Run `./patchPK` with the desired configuration
```
./patchPK -a=FOO -p=com.foo.bar -s=emulator|device|tcpip --dec
```
1. **[optional]** Tamper with the SMALI in `/apps/{APP_SHORTNAME}/smali`
2. Recompile
```
./patchPK -a=FOO -p=com.foo.bar --rec
```   
## Flags+args:
---
```
-a=app's shortname: whatever name you want to identify your app with (eg. -a=FOO)
-p=https://play.google.com/store/apps/details?id=com.foo.bar -> -p=com.foo.bar
-s=device|emulator|tcpip: source to pull the raw app from. Leaving blank will use the default local folder to load an app's by it's name (./apks/{APP_SHORTNAME}.apk)
-d=device|emulator|tcpip: destination to install a patched app to
--dec: decompile. An APK corresponding to the app name needs to be in /apps/{APP_SHORTNAME}/rawPK first.
--rec: recompile. A SMALI folder needs to be in /apps/{APP_SHORTNAME}/smali.
--ow: overwrite previous outputs for current app (1=interactive, 2=force)
```
## File structure:
---
```
- apks <- APKs from device|emulator|tcpip to play with are stored here
    - ...apk1
    - ...apk
- apps <- Apps that we're tampering with are stored here
    - FOO
        - rawPK <- A copy of the app's raw APK
            - smali <- The raw APK's smali code
            - java <- The raw APK JAR file
        - patchedPK <- The tampered APK is stored here at the end of the process
            - smali <- The tampered APK's smali code
            - java <- The tampered APK JAR file
```