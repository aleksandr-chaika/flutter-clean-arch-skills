# CI/CD & Visual Regression with Maestro

## CI/CD: GitHub Actions

```yaml
# .github/workflows/maestro.yml
name: Maestro E2E Tests

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  e2e-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: Install Maestro
        run: curl -fsSL "https://get.maestro.mobile.dev" | bash

      - name: Build APK
        run: flutter build apk --debug

      - name: Setup Android Emulator
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 33
          script: |
            adb install build/app/outputs/flutter-apk/app-debug.apk
            ~/.maestro/bin/maestro test .maestro/flows/smoke_test.yaml

      - name: Upload Screenshots
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: maestro-screenshots
          path: ~/.maestro/tests/
```

## Visual Regression Testing

### Capture Baseline

```bash
# First run creates baseline screenshots
maestro test .maestro/flows/smoke_test.yaml

# Screenshots saved to ~/.maestro/tests/
```

### Compare with Baseline

```yaml
# In flow
- takeScreenshot: "home_screen"

# Visual assertion (Maestro Cloud)
- assertVisualEquals: "baseline/home_screen"
```

### Pixel Perfect Validation

```yaml
- tapOn:
    id: "product_card"
    index: 0
- waitForAnimationToEnd
- takeScreenshot: "product_details_screen"

# Manual comparison:
# 1. Export screenshot
# 2. Overlay in Figma
# 3. Check pixel differences
```

---

## Troubleshooting

### Element Not Found

```yaml
# Debug: screenshot current state
- takeScreenshot: "debug_current_screen"

# Try different selectors
- tapOn: "Login"              # By text
- tapOn:
    id: "login_button"        # By Key (preferred)
- tapOn:
    point: "50%,90%"          # By coordinates (last resort)
```

### Timing Issues

```yaml
# Increase wait time
- extendedWaitUntil:
    visible: "Dashboard"
    timeout: 15000            # 15 seconds

# Wait for animations
- waitForAnimationToEnd
```

### App State Issues

```yaml
# Always start fresh for critical tests
- launchApp:
    clearState: true
    clearKeychain: true       # iOS only
```

### Network Issues

```yaml
# Wait longer for API calls
- extendedWaitUntil:
    visible:
      id: "content"
    timeout: 30000            # 30 seconds for slow APIs
```

### Emulator Issues

```bash
# Check connected devices
adb devices

# Restart ADB
adb kill-server && adb start-server

# Check Maestro can see device
maestro hierarchy

# Verbose output for debugging
maestro test --debug .maestro/flows/test.yaml
```
