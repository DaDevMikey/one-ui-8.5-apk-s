#!/system/bin/sh
#
# This is the main installation script for your module
#

# Stop the script if any command fails
set -e

# --- Module Variables ---

# Base URL for the release
RELEASE_URL="https://github.com/DaDevMikey/one-ui-8.5-apk-s/releases/download/CYJH"

# List of APK filenames, one per line.
APK_LIST="
AirCommand.apk
BudsUniteManager.apk
DesktopModeUiService.apk
Digital.Wellbeing.apk
DigitalWellbeing.apk
DynamicLockscreen.apk
GalleryWidget.apk
GameOptimizingService.apk
Moments.apk
MultiControl.apk
PhotoEditor_AIFull.apk
PrivacyDashboard.apk
Routines.apk
SamsungCamera.apk
SamsungContacts.apk
SamsungContactsProvider.apk
SamsungDialer.apk
SamsungGallery2018.apk
SamsungInCallUI.apk
SamsungMessages.apk
SamsungSmartSuggestions.apk
SecMyFiles2020.apk
SecSettingsIntelligence.apk
SecSetupWizard_Global.apk
ShareLive.apk
SmartCapture.apk
SmartManager_v5.apk
TelephonyUI.apk
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

# --- Main Script ---

ui_print " "
ui_print "*********************************"
ui_print "  One UI 8.5 APK Installer"
ui_print "  by DaDevMikey"
ui_print "*********************************"
ui_print " "

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
mkdir -p $TMP_DIR

# Use a POSIX-compliant while-read loop to process the list
echo "$APK_LIST" | while read -r FILENAME; do
  [ -z "$FILENAME" ] && continue # Skip empty lines

  URL="$RELEASE_URL/$FILENAME"
  APK_PATH="$TMP_DIR/$FILENAME"

  ui_print " "
  ui_print "-> Downloading: $FILENAME"

  # Download with wget. -O specifies the output file.
  if wget -O "$APK_PATH" "$URL"; then
    ui_print "   Download complete. Installing..."

    # Install with pm install
    pm install -r -g "$APK_PATH"

    ui_print "   Installation of $FILENAME complete."

    # Clean up the downloaded file
    rm "$APK_PATH"

  else
    ui_print "   ! DOWNLOAD FAILED for $FILENAME. Skipping."
  fi
done # End of while loop

ui_print " "
ui_print "*********************************"
ui_print "  All tasks complete!"
ui_print "*********************************"
ui_print " "

exit 0