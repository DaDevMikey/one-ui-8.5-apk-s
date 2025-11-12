#!/system/bin/sh
#
# This is the main installation script for your module
#

# Stop the script if any command fails
set -e

# --- Module Variables ---

# Base URL for the release
RELEASE_URL_LATEST="https://github.com/DaDevMikey/one-ui-8.5-apk-s/releases/download/CYJO"
RELEASE_URL_LEGACY="https://github.com/DaDevMikey/one-ui-8.5-apk-s/releases/download/CYJH"

# List of APK filenames, one per line.
APK_LIST="
AirCommand.apk
BudsUniteManager.apk
DesktopModeUiService.apk
DeviceDiagnostics.apk
DigitalWellbeing.apk
DynamicLockscreen.apk
GalaxyApps_OPEN.apk
GalleryWidget.apk
HoneyBoard.apk
KnoxDesktopLauncher.apk
MyDevice.apk
Personalization.apk
PhoneErrService.apk
PhoneNumberService.apk
PhotoEditor_AIFull.apk
PhotoRemasterService.apk
PrivacyDashboard.apk
Routines.apk
SamsungCamera.apk
SamsungContacts.apk
SamsungContactsProvider.apk
SamsungDeviceHealthManagerService.apk
SamsungDialer.apk
SamsungGallery2018.apk
SamsungInCallUI.apk
SamsungVideoPlayer.apk
SecSettingsIntelligence.apk
SecSetupWizard_Global.apk
SecTelephonyProvider.apk
SetupWizard.apk
SmartCapture.apk
SmartManager_v6_DeviceSecurity.apk
TelephonyUI.apk
ThemeStore.apk
VideoEditorLite_Dream_N.apk
VirtualDeviceManager.apk
wallpaper-res.apk
SecMyFiles2020.apk
SamsungSmartSuggestions.apk
MultiControl.apk
Moments.apk
Digital.Wellbeing.apk
"

# List of legacy APKs to download from the CYJH release
LEGACY_APK_LIST="
GameOptimizingService.apk
SamsungMessages.apk
ShareLive.apk
"

# List of APKs known to cause issues on Android 15+
CRASHING_APKS="
SamsungContactsProvider.apk
SamsungCamera.apk
"

# The ID of the module we're checking for
ASKS_DISABLER_ID="asks_disabler"

# Temp directory for downloads
TMP_DIR="/data/local/tmp"

# --- Functions ---

# Function to print messages to the Magisk/KSU install log
ui_print() {
  echo "$1"
}

# Function to check for volume key input
get_key_input() {
  ui_print " "
  ui_print "Please confirm installation:"
  ui_print "   Vol Up   = YES, install"
  ui_print "   Vol Down = NO, cancel"
  
  while true; do
    KEY=$(getevent -lc 1 2>&1 | grep 'KEY_')
    if $(echo "$KEY" | grep -q "KEY_VOLUMEUP"); then
      return 0
    elif $(echo "$KEY" | grep -q "KEY_VOLUMEDOWN"); then
      return 1
    fi
  done
}

# Function to ask user to skip crashing apps on newer Android
confirm_risky_install() {
  ui_print " "
  ui_print "! WARNING: $1 is known to crash on your Android version."
  ui_print "  It is recommended to skip this."
  ui_print "  If you proceed and encounter issues, you can uninstall updates"
  ui_print "  for the app in its App Info page to revert to the stock version."
  ui_print " "
  ui_print "  Do you want to install it anyway?"
  ui_print "    Vol Up   = YES, install"
  ui_print "    Vol Down = NO, skip"

  get_key_input
  return $?
}

# --- Main Script ---

ui_print " "
ui_print "*********************************"
ui_print "  One UI 8.5 APK Installer"
ui_print "  by DaDevMikey (@MikeyDoesTech)"
ui_print "*********************************"
ui_print " "

# Get Android SDK version
SDK_VERSION=$(getprop ro.build.version.sdk)

# Determine Android and One UI version for display
ANDROID_DISPLAY_VERSION=""
ONE_UI_DISPLAY_VERSION=""

if [ "$SDK_VERSION" -eq 35 ]; then
  ANDROID_DISPLAY_VERSION="15"
  ONE_UI_DISPLAY_VERSION="7"
elif [ "$SDK_VERSION" -eq 36 ]; then # Assuming Android 16 is SDK 36
  ANDROID_DISPLAY_VERSION="16"
  ONE_UI_DISPLAY_VERSION="8"
else
  ANDROID_DISPLAY_VERSION="Unknown/below android 15 (SDK $SDK_VERSION)"
  ONE_UI_DISPLAY_VERSION="Unknown"
fi

# Display a warning for Android 15 (One UI 7) and above
if [ "$SDK_VERSION" -ge 35 ]; then
  ui_print " "
  ui_print "******************************************************************"
  ui_print "! WARNING: One UI $ONE_UI_DISPLAY_VERSION (Android $ANDROID_DISPLAY_VERSION) Detected"
  ui_print "******************************************************************"
  ui_print " "
  ui_print " Your warranty is now void."
  ui_print " "
  ui_print " I am not responsible for bricked devices, dead SD cards,"
  ui_print " thermonuclear war, or you getting fired because the alarm app"
  ui_print " failed. Please do some research if you have any concerns about"
  ui_print " doing this to your device. YOU are choosing to make these"
  ui_print " modifications, and if you point the finger at me for messing up"
  ui_print " your device, I will laugh at you."
  ui_print " "
  ui_print " I am also not responsible for you getting in trouble for using"
  ui_print " any of the features in this module, including but not limited to"
  ui_print " Call Recording, 5GHz Hotspot, Bixby, leaked APK's etc."
  ui_print " "
fi

# 1. Ask for confirmation
if ! get_key_input; then
  ui_print " "
  ui_print "Cancelled by user (Volume Down)."
  ui_print " "
  exit 1
fi

ui_print " "
ui_print "Installation confirmed (Volume Up)."

# 2. Check for ASKS Disabler
ui_print "Checking for ASKS Disabler..."
if [ -d "/data/adb/modules/$ASKS_DISABLER_ID" ]; then
  ui_print "-> Found: ASKS Disabler is installed."
else
  ui_print " "
  ui_print "! ERROR: ASKS Disabler module not found."
  ui_print "   This module is required."
  ui_print "   Please install 'asks_disabler' and try again."
  exit 1
fi

# 3. Download and Install APKs
ui_print " "
ui_print "Starting download and installation of APKs..."
ui_print "(Each dot represents downloaded data)"
mkdir -p $TMP_DIR

# Use a POSIX-compliant while-read loop to process the list
echo "$APK_LIST" | while read -r FILENAME; do
  [ -z "$FILENAME" ] && continue # Skip empty lines

  # On Android 15+ (SDK 35+), check if the APK is in the crashing list
  if [ "$SDK_VERSION" -eq 35 ] && echo "$CRASHING_APKS" | grep -q "$FILENAME"; then
    if confirm_risky_install "$FILENAME"; then
      ui_print " "
      ui_print "-> User chose to proceed with installation for $FILENAME."
    else
      ui_print " "
      ui_print "-> Skipping $FILENAME as requested by user."
      continue
    fi
  fi


  URL="$RELEASE_URL_LATEST/$FILENAME"
  APK_PATH="$TMP_DIR/$FILENAME"

  ui_print " "
  ui_print "-> Downloading $FILENAME..."

  # Download with wget.
  # -O: output file
  if wget -O "$APK_PATH" "$URL"; then
    ui_print "-> Download complete. Installing..."

    # Install with pm install, checking for failure
    if pm install -r -g "$APK_PATH"; then
      ui_print "-> Installation of $FILENAME complete."
    else
      ui_print "! INSTALLATION FAILED for $FILENAME. Skipping."
    fi

    # Clean up the downloaded file
    rm "$APK_PATH"
  else
    ui_print "! DOWNLOAD FAILED for $FILENAME. Skipping."
  fi
done # End of while loop

# 4. Download and Install Legacy APKs from CYJH
ui_print " "
ui_print "Starting download and installation of legacy APKs..."

# Use a POSIX-compliant while-read loop to process the legacy list
echo "$LEGACY_APK_LIST" | while read -r FILENAME; do
  [ -z "$FILENAME" ] && continue # Skip empty lines

  # We can skip the Android 15+ check for these as they are older versions

  URL="$RELEASE_URL_LEGACY/$FILENAME"
  APK_PATH="$TMP_DIR/$FILENAME"

  ui_print " "
  ui_print "-> Downloading $FILENAME (legacy)..."

  # Download with wget.
  if wget -O "$APK_PATH" "$URL"; then
    ui_print "-> Download complete. Installing..."

    # Install with pm install, checking for failure
    if pm install -r -g "$APK_PATH"; then
      ui_print "-> Installation of $FILENAME complete."
    else
      ui_print "! INSTALLATION FAILED for $FILENAME. Skipping."
    fi

    # Clean up the downloaded file
    rm "$APK_PATH"
  else
    ui_print "! DOWNLOAD FAILED for $FILENAME. Skipping."
  fi
done # End of while loop

ui_print " "
ui_print "*********************************"
ui_print "  All tasks complete!"
ui_print "*********************************"
ui_print " "

exit 0