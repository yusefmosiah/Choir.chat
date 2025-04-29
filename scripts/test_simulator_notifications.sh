#!/bin/bash
# Script to test push notifications in the iOS Simulator
# This script generates a JSON payload for testing push notifications in the simulator

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Choir Push Notification Simulator Test${NC}"
echo "This script helps test push notifications in the iOS Simulator"
echo

# Check if the simulator is running
if ! xcrun simctl list devices | grep -q "(Booted)"; then
  echo -e "${RED}Error: No simulator is currently running.${NC}"
  echo "Please start a simulator before running this script."
  exit 1
fi

# Get the booted simulator's UDID
SIMULATOR_UDID=$(xcrun simctl list devices | grep "(Booted)" | head -n 1 | sed -E 's/.*\(([A-Za-z0-9-]+)\).*/\1/')

if [ -z "$SIMULATOR_UDID" ]; then
  echo -e "${RED}Error: Could not determine the UDID of the booted simulator.${NC}"
  exit 1
fi

echo -e "${GREEN}Found booted simulator with UDID: ${YELLOW}$SIMULATOR_UDID${NC}"
echo

# Ask for notification type
echo "Select notification type:"
echo "1) Citation notification"
echo "2) Test notification"
read -p "Enter choice (1-2): " NOTIFICATION_TYPE_CHOICE

# Set default values
TITLE="Choir Notification"
BODY="This is a test notification"
NOTIFICATION_TYPE="test"
VECTOR_ID=""
CITING_WALLET_ADDRESS=""

case $NOTIFICATION_TYPE_CHOICE in
  1)
    NOTIFICATION_TYPE="citation"
    TITLE="Your content was cited!"
    BODY="Someone cited your content"
    
    # Ask for vector ID
    read -p "Enter vector ID (or leave empty for test_vector_id): " VECTOR_ID
    VECTOR_ID=${VECTOR_ID:-test_vector_id}
    
    # Ask for citing wallet address
    read -p "Enter citing wallet address (or leave empty for test_wallet_address): " CITING_WALLET_ADDRESS
    CITING_WALLET_ADDRESS=${CITING_WALLET_ADDRESS:-test_wallet_address}
    ;;
  2)
    NOTIFICATION_TYPE="test"
    TITLE="Test Notification"
    BODY="This is a test notification from Choir"
    ;;
  *)
    echo -e "${RED}Invalid choice. Using test notification.${NC}"
    ;;
esac

# Create the JSON payload
echo -e "${GREEN}Creating notification payload...${NC}"

# Base payload
PAYLOAD='{
  "aps": {
    "alert": {
      "title": "'"$TITLE"'",
      "body": "'"$BODY"'"
    },
    "sound": "default",
    "badge": 1
  },
  "notification_type": "'"$NOTIFICATION_TYPE"'"'

# Add vector_id and citing_wallet_address if this is a citation notification
if [ "$NOTIFICATION_TYPE" == "citation" ]; then
  PAYLOAD="$PAYLOAD"',
  "vector_id": "'"$VECTOR_ID"'",
  "citing_wallet_address": "'"$CITING_WALLET_ADDRESS"'"'
fi

# Close the JSON object
PAYLOAD="$PAYLOAD"'
}'

echo -e "${YELLOW}Payload:${NC}"
echo "$PAYLOAD" | python -m json.tool

# Save the payload to a temporary file
TEMP_FILE=$(mktemp)
echo "$PAYLOAD" > "$TEMP_FILE"

echo
echo -e "${GREEN}Sending notification to simulator...${NC}"

# Send the notification to the simulator
xcrun simctl push "$SIMULATOR_UDID" chat.choir "$TEMP_FILE"

# Check if the command was successful
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Notification sent successfully!${NC}"
  echo "Check the simulator for the notification."
else
  echo -e "${RED}Failed to send notification.${NC}"
  echo "Make sure the app is installed on the simulator and has the bundle ID 'chat.choir'."
fi

# Clean up
rm "$TEMP_FILE"
