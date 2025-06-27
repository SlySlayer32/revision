# Firebase Remote Config Template Import Guide

## 🚀 Quick Setup (1-Click Import)

Instead of manually creating each parameter, use this pre-configured template to set up all AI model parameters instantly.

## 📁 Template File

Use the included template: `firebase_remote_config_template.json`

This template includes:

- ✅ All 11 AI parameters with proper defaults
- ✅ Smart conditions for development/premium users
- ✅ Parameter groups for better organization
- ✅ Proper data types and descriptions

## 🔧 Import Steps

### Method 1: Firebase CLI (Recommended)

1. **Install Firebase CLI** (if not already installed):

   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:

   ```bash
   firebase login
   ```

3. **Navigate to your project directory**:

   ```bash
   cd path/to/your/revision/project
   ```

4. **Import the template**:

   ```bash
   firebase remoteconfig:set firebase_remote_config_template.json
   ```

5. **Verify import**:

   ```bash
   firebase remoteconfig:get
   ```

### Method 2: Firebase Console (Manual Import)

1. **Download the template file** from your project
2. **Go to Firebase Console** → Your Project → Remote Config
3. **Click the menu (⋮)** in the top right
4. **Select "Import parameters"**
5. **Upload** `firebase_remote_config_template.json`
6. **Review and publish** the imported parameters

### Method 3: REST API (Advanced)

```bash
# Get access token
firebase auth:ci

# Import config (replace PROJECT_ID and ACCESS_TOKEN)
curl -X PUT \
  https://firebaseremoteconfig.googleapis.com/v1/projects/PROJECT_ID/remoteConfig \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d @firebase_remote_config_template.json
```

## 📋 What Gets Imported

### Parameters (11 total)

| Parameter | Default Value | Type | Description |
|-----------|---------------|------|-------------|
| `ai_gemini_model` | `gemini-2.5-flash` | String | Primary model for text/analysis |
| `ai_gemini_image_model` | `gemini-2.0-flash-preview-image-generation` | String | Model for image generation |
| `ai_temperature` | `0.4` | Number | Creativity level (0.0-1.0) |
| `ai_max_output_tokens` | `1024` | Number | Maximum response length |
| `ai_top_k` | `40` | Number | Top-K sampling parameter |
| `ai_top_p` | `0.95` | Number | Top-P sampling parameter |
| `ai_analysis_system_prompt` | [Long text] | String | System instruction for analysis |
| `ai_editing_system_prompt` | [Long text] | String | System instruction for editing |
| `ai_request_timeout_seconds` | `30` | Number | Request timeout duration |
| `ai_enable_advanced_features` | `true` | Boolean | Feature toggle |
| `ai_debug_mode` | `false` | Boolean | Debug logging control |

### Smart Conditions (3 total)

1. **`development_env`** - Applies to development builds
   - Higher temperature for experimentation
   - Extended timeouts for debugging
   - Debug mode enabled

2. **`premium_users`** - For premium tier users
   - Access to more powerful models
   - Higher token limits

3. **`debug_mode_users`** - 5% of users for testing
   - Debug logging enabled for monitoring

### Parameter Groups (4 total)

- **AI Model Configuration** - Model selection parameters
- **Generation Parameters** - Creativity and output control
- **System Instructions** - AI behavior prompts
- **Performance & Control** - Timeouts and feature flags

## ✅ Verification Steps

After import, verify everything is working:

1. **Check Firebase Console**:
   - Go to Remote Config
   - Verify all 11 parameters are present
   - Check conditions are created
   - Confirm parameter groups are organized

2. **Test in your app**:

   ```bash
   flutter run
   ```

   - Open Dashboard → "Test Firebase AI"
   - Tap "Refresh Config" button
   - Verify current config values are displayed
   - Test with a prompt to confirm AI is working

3. **Check logs** for successful initialization:

   ```
   ✅ Firebase Remote Config initialized successfully
   ✅ Google AI (Gemini API) models initialized successfully
   ```

## 🎛️ Post-Import Customization

### Adjust Default Values

Update any defaults in Firebase Console:

1. Click on a parameter
2. Edit "Default value"
3. Click "Update" then "Publish changes"

### Add Custom Conditions

Create your own conditions:

1. Click "Add condition"
2. Define rules (e.g., `app.version >= '1.2.0'`)
3. Apply to specific parameters

### Modify System Prompts

Customize AI behavior:

1. Edit `ai_analysis_system_prompt` or `ai_editing_system_prompt`
2. Add your specific requirements
3. Test with real prompts

## 🚨 Troubleshooting

### Import Failed

- **Check file format**: Must be valid JSON
- **Verify permissions**: Ensure you have Firebase project access
- **Try smaller batches**: Import conditions first, then parameters

### Parameters Not Appearing

- **Refresh Firebase Console** (F5)
- **Check project selection** (correct Firebase project)
- **Verify CLI project**: `firebase use --list`

### App Not Using New Values

- **Force refresh in app**: Tap "Refresh Config" button
- **Check network connection**: Remote Config requires internet
- **Restart app**: May need to restart to pick up changes

## 🎯 Quick Test Commands

After import, test everything:

```bash
# Test Firebase CLI connection
firebase remoteconfig:get --pretty

# Test app compilation
flutter analyze

# Test app with Remote Config
flutter run --dart-define=ENVIRONMENT=development
```

## 📝 Template Customization

To modify the template before import:

1. **Edit** `firebase_remote_config_template.json`
2. **Change default values** to match your needs
3. **Add/remove conditions** based on your user segments
4. **Modify prompts** for your specific use case
5. **Re-import** with updated template

## 🎉 Success Indicators

You'll know import worked when:

- ✅ Firebase Console shows all 11 parameters
- ✅ App demo widget displays current config values
- ✅ AI requests use Remote Config parameters
- ✅ Debug logs show "Remote Config initialized successfully"
- ✅ Manual refresh updates values instantly

## 🔄 Update Template

To update an existing configuration:

1. **Export current config**:

   ```bash
   firebase remoteconfig:get > current_config.json
   ```

2. **Merge with template** (keep your customizations)

3. **Re-import updated template**:

   ```bash
   firebase remoteconfig:set updated_template.json
   ```

This template gives you **instant AI model control** from Firebase Console with smart defaults and conditions ready to use! 🚀
