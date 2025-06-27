# Firebase Remote Config Template - Quick Import ⚡

This template provides **instant setup** for AI model control via Firebase Remote Config.

## 🚀 Quick Import Options

### Option 1: Firebase CLI (Recommended)
```bash
# Ensure you're logged in and using the correct project
firebase login
firebase use revision-464202

# Import the template
firebase remoteconfig:set firebase_remote_config_template.json

# Verify the import
firebase remoteconfig:get > current_config.json
```

### Option 2: REST API Import
```bash
# Get an access token (if needed)
firebase auth:print-access-token

# Upload via REST API
curl -X PUT \
  "https://firebaseremoteconfig.googleapis.com/v1/projects/revision-464202/remoteConfig" \
  -H "Authorization: Bearer $(firebase auth:print-access-token)" \
  -H "Content-Type: application/json" \
  -d @firebase_remote_config_template.json
```

### Option 3: Manual Upload (Firebase Console)
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select project `revision-464202`
3. Navigate to **Remote Config**
4. Click **"Upload from file"** 
5. Select `firebase_remote_config_template.json`
6. Click **"Publish changes"**

## 📋 What Gets Imported

### ✅ Complete AI Parameter Set
- **11 parameters** for full AI control
- **4 organized parameter groups**
- **3 smart conditions** for user targeting
- **Type safety** with explicit `valueType` definitions

### 🎯 Conditional Logic Included
- **Premium users** get more powerful models (`gemini-1.5-pro`, 2048 tokens)
- **Development environment** gets debug mode and higher creativity
- **5% of users** get debug logging for troubleshooting

### 🛠️ Parameter Groups for Organization
- **AI Model Configuration** - Model selection
- **Generation Parameters** - Fine-tuning controls  
- **System Instructions** - AI behavior and prompts
- **Performance & Control** - Timeouts and feature flags

## 🎉 After Import

1. **Verify Import**: Check Firebase Console > Remote Config
2. **Test in App**: Use the Firebase AI Demo widget
3. **Customize Values**: Adjust parameters for your needs
4. **Publish Changes**: Click "Publish" in Firebase Console

## 🔧 Template Compliance

This template follows the **Firebase Remote Config REST API v1** specification exactly:

- ✅ Proper `RemoteConfig` structure
- ✅ Valid `RemoteConfigCondition` objects
- ✅ Correct `RemoteConfigParameter` format
- ✅ Proper `RemoteConfigParameterGroup` structure
- ✅ Type-safe `valueType` specifications (`STRING`, `NUMBER`, `BOOLEAN`)
- ✅ Valid condition expressions and colors

## 🚨 Important Notes

- **Backup First**: Export your current config before importing
- **Test Environment**: Consider testing in a development project first
- **Review Conditions**: Ensure condition expressions match your app setup
- **Parameter Names**: Must match exactly with your Flutter app code

Ready to import? Choose your preferred method above! 🚀
