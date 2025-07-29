# PWA Icon Fix Instructions

## The Problem
The PWA is showing the Flutter logo instead of your logo1.png because the web icons in `web/icons/` are still the default Flutter icons.

## Manual Fix Required
Since file copying requires manual action, please follow these steps:

### Step 1: Replace Web Icons
You need to manually replace these files in `web/icons/` with your logo1.png:

1. **Icon-192.png** - Resize logo1.png to 192x192 pixels
2. **Icon-512.png** - Resize logo1.png to 512x512 pixels  
3. **Icon-maskable-192.png** - Resize logo1.png to 192x192 pixels (with padding for maskable)
4. **Icon-maskable-512.png** - Resize logo1.png to 512x512 pixels (with padding for maskable)

### Step 2: Online Tool Method (Easiest)
1. Go to https://realfavicongenerator.net/ or https://icon.kitchen/
2. Upload your `assets/logo1.png`
3. Select "Generate PWA icons"
4. Download the generated icons
5. Replace the files in `web/icons/` with the downloaded ones

### Step 3: Manual Resize Method
If you have image editing software:
1. Open `assets/logo1.png`
2. Resize to 192x192 - save as `Icon-192.png` and `Icon-maskable-192.png`
3. Resize to 512x512 - save as `Icon-512.png` and `Icon-maskable-512.png`
4. For maskable icons, add some padding around your logo (about 20% on each side)

### Step 4: Copy Files
Copy the resized icons to replace these files:
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/icons/Icon-maskable-192.png` 
- `web/icons/Icon-maskable-512.png`

### Step 5: Rebuild
```bash
flutter clean
flutter build web --release
```

## What I've Done
✅ Added flutter_launcher_icons package to pubspec.yaml
✅ Configured icon generation with your logo1.png
✅ Restored custom splash screen in web/index.html
✅ Set up proper PWA configuration

## Alternative Quick Fix
If you want a quick test, you can:
1. Copy `assets/logo1.png` to `web/icons/Icon-192.png`
2. Copy `assets/logo1.png` to `web/icons/Icon-512.png`
3. Run `flutter build web --release`

This will at least show your logo instead of Flutter's logo when installing as PWA.
