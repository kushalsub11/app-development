# final_year_project

Flutter app with Android Studio used only for Android hosting tasks such as the emulator, SDK tools, and Gradle/JDK.

## Android Studio Role

Use Android Studio for:

- creating or managing Android emulators
- Android SDK updates
- Gradle sync or Android-specific inspection if needed

Use terminal or your preferred editor for normal development.

## Local Commands

From this project root:

```powershell
.\start-emulator.ps1
.\run-android.ps1
.\android-build.ps1
```

Notes:

- `start-emulator.ps1` starts the first available AVD, or a named one: `.\start-emulator.ps1 Pixel_9`
- `run-android.ps1` runs the Flutter app using Android Studio's bundled JDK
- `android-build.ps1` runs `assembleDebug` by default, or any Gradle task such as `.\android-build.ps1 installDebug`

If no emulator exists yet, create one in Android Studio Device Manager first.
