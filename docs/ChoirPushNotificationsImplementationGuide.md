# Choir Push Notifications Implementation Guide

This guide outlines the steps to test and integrate push notifications for citation events in the Choir app.

## Server Configuration

### Environment Variables
Ensure these environment variables are set on your server:
```
APNS_KEY_ID=YOUR_KEY_ID
APNS_TEAM_ID=YOUR_TEAM_ID
APNS_AUTH_KEY=/path/to/AuthKey_KEYID.p8
APNS_TOPIC=chat.choir
```

### Required Packages
Make sure these packages are installed:
```
pyjwt==2.10.1
cryptography==44.0.2
```

## 1. Test Sending an Actual Notification

### Register a Device Token
1. Run the Choir app in the simulator or on a device
2. Ensure the app requests and receives notification permissions
3. Check the console logs for the device token output
4. Copy the device token for testing

### Test with the API Endpoint
```bash
# From the api directory with venv activated
curl -X POST http://localhost:8000/api/notifications/test-push \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -d '{"device_token": "DEVICE_TOKEN_FROM_CONSOLE"}'
```

## 2. Verify Citation Notifications

### Create Test Vector and Citation
1. Create a test vector with your wallet address:
```bash
curl -X POST http://localhost:8000/api/vectors \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -d '{
    "content": "This is a test vector for citation notifications",
    "metadata": {
      "wallet_address": "YOUR_WALLET_ADDRESS"
    }
  }'
```

2. Note the vector ID from the response

3. Create a citation to that vector:
```bash
curl -X POST http://localhost:8000/api/postchain/langchain \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -d '{
    "query": "Please cite the vector with ID: VECTOR_ID",
    "wallet_address": "DIFFERENT_WALLET_ADDRESS"
  }'
```

4. Check if you receive a push notification on your device

## 3. Start the Server

```bash
# From the api directory with venv activated
uvicorn app.main:app --reload
```

## Swift Integration for Push Notifications

### Update Info.plist
Ensure these capabilities are in your Info.plist:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### Register for Notifications in AppDelegate
The code is already implemented in `PushNotificationManager.swift`, but verify:
1. `registerForPushNotifications()` is called on app launch
2. `updateDeviceToken()` properly formats and sends the token to the server
3. `handleNotificationReceived()` processes different notification types

### Add Notification Observers in TransactionsView
```swift
// In .onAppear
NotificationCenter.default.addObserver(
    forName: NSNotification.Name("RefreshNotifications"),
    object: nil,
    queue: .main
) { _ in
    transactionService.fetchTransactions()
}
```

## Testing in Simulator

1. Run the app in the simulator
2. Use the Simulator menu: Features > Push Notifications
3. Create a JSON payload:
```json
{
  "aps": {
    "alert": {
      "title": "Your content was cited!",
      "body": "Someone cited your content"
    },
    "sound": "default",
    "badge": 1
  },
  "notification_type": "citation",
  "vector_id": "test_vector_id",
  "citing_wallet_address": "test_wallet_address"
}
```
4. Click "Send" to deliver the notification

## Testing in TestFlight

1. Build and archive the app with push notification entitlements
2. Upload to TestFlight
3. Install on a test device
4. Use the test endpoint to send a real notification:
```bash
curl -X POST https://your-production-server.com/api/notifications/test-push \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -d '{"device_token": "DEVICE_TOKEN_FROM_TEST_DEVICE"}'
```

## Troubleshooting

- **No notifications in simulator**: Use the simulator's manual notification feature
- **No notifications on device**: Check APNs environment (sandbox vs. production)
- **Server errors**: Check logs for JWT token generation issues
- **Device token not registering**: Verify the registration endpoint is working
- **Production vs. Development**: For Swift environment targeting, use:
  ```swift
  #if DEBUG && targetEnvironment(simulator)
      // Use devnet/sandbox
  #else
      // Use mainnet/production
  #endif
  ```

## APNs Configuration in Apple Developer Portal

1. **Environment**: Choose "Sandbox & Production" to allow your key to work in both development and production environments
2. **Key Restriction**: Choose "Team Scoped (All Topics)" for flexibility across all your apps
3. **Bundle ID**: Ensure your app's bundle ID matches the `APNS_TOPIC` environment variable

## Notification Payload Structure

```json
{
  "aps": {
    "alert": {
      "title": "Your content was cited!",
      "body": "Someone cited your content: \"content_preview\""
    },
    "sound": "default",
    "badge": 1
  },
  "notification_type": "citation",
  "vector_id": "vector_id_here",
  "citing_wallet_address": "wallet_address_here"
}
```

This implementation provides a complete solution for sending push notifications when users' content is cited, enhancing the user experience and engagement with the app.
