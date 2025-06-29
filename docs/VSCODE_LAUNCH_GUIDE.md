# VS Code Launch Configurations Guide

## 🚀 Available Launch Configurations

Your `.vscode/launch.json` now includes several launch configurations optimized for different development scenarios:

### Primary Development Configurations

#### 🔧 Development

- **Best for:** Daily development work
- **Features:** Auth emulator, development environment, debug tools
- **Platform:** Default (usually the last used device)

#### 🌐 Development Web  

- **Best for:** Web development and testing
- **Features:** Chrome browser, development environment
- **Platform:** Web (Chrome)

#### 🧪 Development + Debug Tools

- **Best for:** Debugging complex issues
- **Features:** All debug tools enabled, enhanced logging
- **Platform:** Default

### Platform-Specific Development

#### 📱 Development Android

- **Best for:** Android-specific testing
- **Features:** Android emulator/device, auth emulator
- **Platform:** Android

#### 🍎 Development iOS

- **Best for:** iOS-specific testing  
- **Features:** iOS simulator/device, auth emulator
- **Platform:** iOS

### Environment Testing

#### 🟡 Staging

- **Best for:** Testing staging environment
- **Features:** Staging Firebase project, production-like settings
- **Platform:** Default

#### 🔴 Production

- **Best for:** Final testing before release
- **Features:** Production Firebase project, no emulators
- **Platform:** Default

## 🔑 Environment Variables Setup

### Required Setup

1. Copy `.env.example` to `.env`:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your Gemini API key:

   ```bash
   GEMINI_API_KEY=your_actual_api_key_here
   ```

3. Get your API key from [Google AI Studio](https://aistudio.google.com/app/apikey)

### VS Code Environment Variable Support

The launch configurations use `${env:GEMINI_API_KEY}` to read from your system environment variables.

#### Option 1: System Environment Variables (Recommended)

Set the environment variable in your system:

**Windows (PowerShell):**

```powershell
$env:GEMINI_API_KEY="your_api_key_here"
```

**Windows (Command Prompt):**

```cmd
set GEMINI_API_KEY=your_api_key_here
```

**macOS/Linux:**

```bash
export GEMINI_API_KEY="your_api_key_here"
```

#### Option 2: VS Code Settings

Add to your VS Code `settings.json`:

```json
{
  "terminal.integrated.env.windows": {
    "GEMINI_API_KEY": "your_api_key_here"
  }
}
```

## 🎯 Usage Tips

### For Daily Development

1. Use **🔧 Development** configuration
2. This includes auth emulator and all development tools
3. Automatically detects environment as 'development'

### For Web Testing

1. Use **🌐 Development Web** configuration
2. Opens in Chrome with development environment
3. URL-based environment detection will work

### For Production Testing

1. Use **🔴 Production** configuration
2. Connects to real Firebase (no emulators)
3. Tests the full production pipeline

### For Environment Debugging

1. Use **🧪 Development + Debug Tools** configuration
2. Enables additional logging and debug features
3. Perfect for troubleshooting environment detection

## 🔍 Debugging Environment Detection

If you need to debug environment detection:

1. Launch with **🧪 Development + Debug Tools**
2. Check the Debug Console for environment logs:
   - `🚀 Starting app in development mode`
   - `🔍 Environment Debug Info: {...}`
   - `🔥 Firebase Debug Info: {...}`

3. Use the Environment Debug Page in the app to see detailed detection info

## 🚨 Troubleshooting

### API Key Issues

- **Problem:** `GEMINI_API_KEY is not set` error
- **Solution:** Ensure environment variable is set before launching VS Code

### Environment Detection Issues  

- **Problem:** Wrong environment detected
- **Solution:** Check the environment debug logs and use explicit `--dart-define=ENVIRONMENT=development`

### Firebase Connection Issues

- **Problem:** Firebase initialization fails
- **Solution:** Check Firebase project configuration and internet connection

### Emulator Issues

- **Problem:** Auth emulator not connecting
- **Solution:** Ensure Firebase emulators are running: `firebase emulators:start`
