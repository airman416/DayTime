# API Key Configuration Setup

This directory contains configuration files for managing API keys securely without committing them to git.

## 🔐 How It Works

- **Template files** (`.template`) are committed to git and show the structure
- **Actual config files** (`.xcconfig`) contain your real API keys and are gitignored
- Xcode reads these files at build time and injects the values into your app

## 📋 Setup Instructions

### Option 1: Manual Setup in Xcode (Recommended)

1. **Open your project in Xcode**

2. **Add the .xcconfig files to your project:**
   - Right-click on the `Config` folder in Xcode
   - Select "Add Files to DayTime..."
   - Select both `Debug.xcconfig` and `Release.xcconfig`
   - Make sure "Copy items if needed" is **unchecked**
   - Click "Add"

3. **Configure the build settings:**
   - Select your project in the navigator
   - Select the "DayTime" target
   - Go to the "Info" tab
   - Under "Configurations", set:
     - Debug: `Config/Debug.xcconfig`
     - Release: `Config/Release.xcconfig`

4. **Add your API keys:**
   - Open `Config/Debug.xcconfig` and `Config/Release.xcconfig`
   - Replace `YOUR_GEMINI_API_KEY_HERE` with your actual Gemini API key
   - Replace `YOUR_SUPERWALL_API_KEY_HERE` with your actual Superwall API key

5. **Build and run** - The app will now read keys from the config files!

### Option 2: Quick Setup (Copy Templates)

If the template files exist, you can copy them:

```bash
cd Config
cp Debug.xcconfig.template Debug.xcconfig
cp Release.xcconfig.template Release.xcconfig
```

Then edit `Debug.xcconfig` and `Release.xcconfig` with your actual API keys.

## ✅ Verification

After setup, verify it's working:

1. Build the app (⌘ + B)
2. Check that it builds successfully
3. Run the app and test the Gemini API functionality
4. The keys should be loaded from the config files, not hardcoded

## 🔒 Security Notes

- ✅ The actual `.xcconfig` files are gitignored (see `.gitignore`)
- ✅ Only template files are committed to git
- ✅ Each developer/CI system needs their own `.xcconfig` files
- ✅ For CI/CD, set these as environment variables or secrets

## 🚀 For CI/CD (GitHub Actions, etc.)

In your CI configuration, you can either:

1. **Create the files dynamically:**
   ```bash
   echo "GEMINI_API_KEY = ${{ secrets.GEMINI_API_KEY }}" > Config/Debug.xcconfig
   echo "SUPERWALL_API_KEY = ${{ secrets.SUPERWALL_API_KEY }}" >> Config/Debug.xcconfig
   cp Config/Debug.xcconfig Config/Release.xcconfig
   ```

2. **Or use environment variables** and modify the build script to inject them

## 📝 Current Keys Location

The app reads keys from:
- `Info.plist` → `GEMINI_API_KEY` and `SUPERWALL_API_KEY`
- These values are substituted from `.xcconfig` files at build time
- Swift code reads from `Bundle.main.infoDictionary`

