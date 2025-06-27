# 🚀 Firebase Remote Config Template - One-Click Setup

## Quick Import (Choose One Method)

### Method 1: PowerShell Script (Easiest)
```powershell
# Run this command in your project root
.\scripts\import-firebase-remote-config.ps1
```

### Method 2: Firebase CLI (Manual)
```bash
# 1. Install Firebase CLI
npm install -g firebase-tools

# 2. Login to Firebase
firebase login

# 3. Set your project
firebase use revision-464202

# 4. Import template
firebase remoteconfig:set firebase_remote_config_template.json
```

### Method 3: Firebase Console (Upload)
1. Go to [Firebase Console](https://console.firebase.google.com/project/revision-464202/config)
2. Click menu (⋮) → "Import parameters"
3. Upload `firebase_remote_config_template.json`
4. Click "Publish changes"

## What Gets Imported

### 11 AI Parameters
- **Model Selection**: `ai_gemini_model`, `ai_gemini_image_model`
- **Generation Control**: `ai_temperature`, `ai_max_output_tokens`, `ai_top_k`, `ai_top_p`
- **System Instructions**: `ai_analysis_system_prompt`, `ai_editing_system_prompt`
- **Performance**: `ai_request_timeout_seconds`, `ai_enable_advanced_features`, `ai_debug_mode`

### 3 Smart Conditions
- **Development**: Higher creativity, extended timeouts, debug enabled
- **Premium Users**: Access to powerful models, higher token limits
- **Debug Users**: 5% of users with debug logging enabled

## Test After Import

1. **Open your app**: `flutter run`
2. **Go to Dashboard** → "Test Firebase AI"
3. **Tap "Refresh Config"** to load imported values
4. **Test with a prompt** to verify AI is working
5. **Check logs** for "Remote Config initialized successfully"

## Customize Values

After import, go to Firebase Console to adjust:
- **Model names** when new versions are released
- **Temperature** for more/less creative responses
- **System prompts** to change AI behavior
- **Timeouts** based on your performance needs

## Files Included

- `firebase_remote_config_template.json` - Ready-to-import template
- `scripts/import-firebase-remote-config.ps1` - Automated import script
- `docs/FIREBASE_REMOTE_CONFIG_TEMPLATE_IMPORT.md` - Detailed guide

## Benefits

✅ **Instant Setup** - All 11 parameters configured in minutes
✅ **Smart Defaults** - Production-ready values included
✅ **A/B Testing Ready** - Conditions for different user segments
✅ **Error-Free** - No manual typing or configuration mistakes
✅ **Best Practices** - Follows Firebase Remote Config guidelines

## Need Help?

- Check `docs/FIREBASE_REMOTE_CONFIG_TEMPLATE_IMPORT.md` for detailed instructions
- Verify Firebase CLI is installed: `firebase --version`
- Ensure you're logged in: `firebase projects:list`
- Test app connectivity: Dashboard → Test Firebase AI
