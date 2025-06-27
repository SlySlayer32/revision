# Firebase Remote Config Setup for AI Model Control

This guide shows you how to set up Firebase Remote Config to control your AI model parameters, prompts, and system instructions from the Firebase Console without rebuilding your app.

## 🚀 Quick Setup with Template

**NEW: Use the included template for instant setup!**

### Option 1: One-Click PowerShell Import (Recommended)

```powershell
# Run this in your project root directory
.\scripts\import-firebase-remote-config.ps1
```

### Option 2: Firebase CLI Import

```bash
firebase login
firebase use revision-464202
firebase remoteconfig:set firebase_remote_config_template.json
```

### Option 3: Manual Setup (continue reading below)

---

## 🎯 What You Can Control

With Firebase Remote Config, you can dynamically control:

- **Model Selection**: Switch between different Gemini models
- **Generation Parameters**: Temperature, max tokens, top-K, top-P
- **System Instructions**: Update AI behavior and personality
- **Prompts**: Modify how the AI processes requests
- **Feature Flags**: Enable/disable advanced features
- **Timeouts**: Adjust request timeout values
- **Debug Settings**: Control logging and debug output

## 🚀 Setup Steps

### Step 1: Access Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your `revision-464202` project
3. In the left sidebar, click **Remote Config**

### Step 2: Create AI Parameters

Click **Add parameter** for each of the following:

#### Model Configuration Parameters

**Parameter: `ai_gemini_model`**

- Default value: `gemini-2.5-flash`
- Description: `Primary Gemini model for text analysis and processing`

**Parameter: `ai_gemini_image_model`**

- Default value: `gemini-2.0-flash-preview-image-generation`
- Description: `Gemini model for image generation and processing`

#### Generation Parameters

**Parameter: `ai_temperature`**

- Default value: `0.4`
- Description: `Controls creativity vs consistency (0.0-1.0). Lower = more focused, Higher = more creative`

**Parameter: `ai_max_output_tokens`**

- Default value: `1024`
- Description: `Maximum tokens in AI response. Higher = longer responses`

**Parameter: `ai_top_k`**

- Default value: `40`
- Description: `Top-K sampling parameter. Lower = more focused responses`

**Parameter: `ai_top_p`**

- Default value: `0.95`
- Description: `Top-P (nucleus) sampling parameter. Lower = more focused responses`

#### System Instructions

**Parameter: `ai_analysis_system_prompt`**

- Default value:

```
You are an expert image analysis AI. Analyze the provided image and marked object to create precise editing instructions.

Focus on:
1. Object identification and boundaries
2. Background reconstruction techniques  
3. Lighting and shadow analysis
4. Color harmony considerations
5. Realistic removal strategies

Provide actionable editing instructions.
```

- Description: `System instruction for image analysis tasks`

**Parameter: `ai_editing_system_prompt`**

- Default value:

```
You are an expert AI image editor using Gemini 2.0 Flash Preview Image Generation. Edit the provided image based on user instructions with these requirements:

1. Generate a new version of the image with the requested edits applied
2. If removing objects: use content-aware reconstruction to fill the space naturally
3. If enhancing: improve lighting, contrast, color balance, and composition
4. Maintain original image resolution and quality
5. Preserve overall composition and visual coherence
6. Apply changes seamlessly and realistically

Return the edited image directly as the output.
```

- Description: `System instruction for image editing tasks`

#### Performance & Control Parameters

**Parameter: `ai_request_timeout_seconds`**

- Default value: `30`
- Description: `Timeout for AI requests in seconds`

**Parameter: `ai_enable_advanced_features`**

- Default value: `true`
- Description: `Enable experimental AI features`

**Parameter: `ai_debug_mode`**

- Default value: `false`
- Description: `Enable detailed logging for AI operations`

### Step 3: Publish Configuration

1. Click **Publish changes** in the top right
2. Add a description like "Initial AI model configuration"
3. Click **Publish**

## 🎛️ Advanced Usage

### A/B Testing Different Models

1. In Remote Config, click on a parameter (e.g., `ai_gemini_model`)
2. Click **Add condition**
3. Create conditions like:
   - **Condition name**: `premium_users`
   - **Applies to**: Users with custom attribute `tier = premium`
   - **Value**: `gemini-1.5-pro` (more powerful model)

### Environment-Specific Configuration

Create conditions for different environments:

**Development Environment:**

- **Condition name**: `development_env`
- **Applies to**: App with `app_id` contains `dev`
- **Values**: Higher debug settings, faster timeouts

**Production Environment:**

- **Condition name**: `production_env`
- **Values**: Optimized for performance and cost

### Time-Based Configuration

**Holiday Themes:**

- **Condition name**: `holiday_season`
- **Applies to**: Date/time within holiday period
- **Values**: Special holiday-themed prompts

## 📱 How It Works in Your App

### Automatic Updates

Your app automatically:

1. Fetches latest config on startup
2. Refreshes config every hour (configurable)
3. Falls back to hardcoded defaults if Remote Config fails
4. Logs config changes when debug mode is enabled

### Manual Refresh

You can manually refresh config in your app:

```dart
// In your service or widget
final geminiService = GeminiAIService();
await geminiService.refreshConfig();
```

### Debug Information

Get current config values:

```dart
final debugInfo = geminiService.getConfigDebugInfo();
print('Current AI config: $debugInfo');
```

## 🔧 Testing Your Configuration

### 1. Test in Firebase Console

1. Go to Remote Config
2. Click **Preview** next to any parameter
3. Test different values before publishing

### 2. Test in Your App

Use the Firebase AI Demo widget in your app:

1. Open your app
2. Go to Dashboard
3. Tap "Test Firebase AI"
4. Try different prompts
5. Check debug output for config values

### 3. Verify Changes

After updating config:

1. Wait 1-5 minutes for propagation
2. Restart your app or call `refreshConfig()`
3. Check logs for "Remote Config refreshed successfully"

## 🎯 Common Use Cases

### 1. Model Upgrades

When Google releases new models:

1. Update `ai_gemini_model` parameter
2. Test with a small user group using conditions
3. Roll out to all users gradually

### 2. Cost Optimization

Reduce costs by:

- Lowering `ai_max_output_tokens` during high usage
- Using lighter models for basic tasks
- Adjusting `ai_temperature` for more focused responses

### 3. Quality Improvements

Improve responses by:

- Updating system prompts based on user feedback
- A/B testing different prompt strategies
- Adjusting generation parameters for your use case

### 4. Feature Rollouts

Control new features:

- Use `ai_enable_advanced_features` for gradual rollouts
- Create user segment conditions
- Monitor performance before full release

## 🚨 Best Practices

### 1. Always Test Before Publishing

- Use Firebase Console preview
- Test with development environment first
- Monitor error rates after changes

### 2. Keep Backups

- Document working configurations
- Use descriptive change descriptions
- Consider rollback plans

### 3. Monitor Performance

- Watch for increased latency with new models
- Monitor token usage for cost control
- Track error rates after config changes

### 4. Use Conditions Wisely

- Start with simple percentage rollouts
- Use app version conditions for compatibility
- Consider user segment targeting

## 🔍 Troubleshooting

### Config Not Updating

1. Check if config was published in Firebase Console
2. Verify app has internet connection
3. Try manual refresh: `await geminiService.refreshConfig()`
4. Check logs for Remote Config errors

### App Using Wrong Values

1. Verify parameter names match exactly
2. Check data types (string vs number vs boolean)
3. Ensure app version supports the parameters
4. Check condition logic in Firebase Console

### Performance Issues

1. Check if new model is heavier than previous
2. Verify timeout values are reasonable
3. Monitor token usage in new configuration
4. Consider rolling back to previous config

## 📊 Monitoring

### Key Metrics to Watch

- **Response Times**: New models may be slower/faster
- **Token Usage**: Different parameters affect cost
- **Error Rates**: Invalid configs can cause failures
- **User Satisfaction**: Monitor feedback on AI responses

### Firebase Analytics Integration

The app automatically logs:

- AI model usage events
- Remote Config parameter changes
- Performance metrics
- Error occurrences

## 🎉 Success

You now have complete control over your AI model behavior from the Firebase Console!

Changes take effect within minutes without requiring app updates, giving you:

- ✅ Instant model upgrades
- ✅ Real-time prompt optimization  
- ✅ A/B testing capabilities
- ✅ Cost and performance control
- ✅ Feature flag management

Your users will experience improved AI responses as you continuously optimize the configuration based on real usage patterns and feedback.
