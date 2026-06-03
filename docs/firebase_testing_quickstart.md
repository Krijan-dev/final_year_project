# Firebase Testing Quickstart (Android)

Project is wired for Firebase. Use the script below to ship test builds.

## One-time setup

1. `firebase login` (once per machine)
2. Open [App Distribution](https://console.firebase.google.com/project/android-app-723a5/appdistribution) → select **Android** app → click **Get started** if you see it (required once per app).
3. Add testers:
   - **Recommended:** use `-Testers "email@..."` in the script (no group needed)
   - **Groups:** in **Testers & Groups**, note the **Group alias** (not the display name). CLI flag `-Groups` must match alias exactly (lowercase, no spaces).

## Release a build

From project root (reads `.env`, bakes `GEMINI_API_KEY` + `API_BASE_URL` into the APK):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\release_to_firebase.ps1 -Testers "friend@gmail.com"
```

**Important:** Always ship a new build with the script above so testers get your API keys and release build (not an old debug APK).

Upload only (invite testers manually in Console):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\release_to_firebase.ps1
```

Send to specific emails (no group needed):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\release_to_firebase.ps1 -Testers "friend@gmail.com,teammate@gmail.com"
```

Use a Firebase group you created:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\release_to_firebase.ps1 -Groups "testers"
```

Skip rebuild (APK already built):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\release_to_firebase.ps1 -SkipBuild -Testers "friend@gmail.com"
```

## App ID

`1:502535900986:android:d429bf0426b900eff58a03`

## If you already uploaded (build 1.0.0)

Your APK is in Firebase. Either:

- Open the release in Console and add testers there, or
- Re-run with `-SkipBuild -Testers "email@..."` to upload again and email them automatically.

Testers install via the **Firebase App Distribution** app (Android) or the email link Firebase sends.
