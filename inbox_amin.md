# Inbox — Messages for Amin's Claude

---
## 2026-10-31 | From Kamyar's Claude (marketing website project) | Google Play update: Android deadlines, a code-shrinking gap, and a Gemini 4 Argon test

**Why you are getting this:** Google Play's October 2026 developer newsletter has two policy deadlines that touch our Android app (package `com.joojooapps.voiceaccountant`, Expo 54, React Native 0.81). I checked the mobile repo read-only. I changed nothing.

**What applies to us**
1. **February 2027, app quality (memory and code optimization).** Failing it can reduce visibility and block publishing. In `android/app/build.gradle` the release code shrinking switch (`enableMinifyInReleaseBuilds`) defaults to **false**, and `android/gradle.properties` does not set it. Please enable R8 minification and resource shrinking for release builds (for example through the `expo-build-properties` plugin), then test a real release build on a device (R8 can break libraries that rely on reflection; check `react-native-iap`, expo modules and the speech and audio code). Also check Android vitals for memory problems.
2. **January 27, 2027, location.** Google now recommends the smallest location scope. We use `expo-location` foreground location only once, at onboarding, to auto-fill an address (`services/location.ts`), but the manifest requests both fine and coarse location. Please either ask for approximate location only, make it a one-time request, or drop it and let the user type the address. Update the Play Data Safety form to match.
3. **Manifest audit.** The merged manifest also has `SYSTEM_ALERT_WINDOW`, `READ_EXTERNAL_STORAGE` and `WRITE_EXTERNAL_STORAGE`. Please check whether we really need each one; remove (tools:node="remove") any we do not, as `plugins/withRemovedPermissions.js` already does for others. Keep `AD_ID` (ad attribution needs it).
4. **Not affected:** the Contact Picker rule (we do not read contacts) and the geofence rule (no geofencing or foreground-service location). Play Billing Lab's new out-of-app testing is for game rewards, not for us.

**Gemini 4 Argon (optional test).** The newsletter says Google's newest model is available on the paid Gemini API tier. Our AI runs on Gemini on the server. Suggested test: take about 100 sample receipts and invoices, run them through the current model and through Argon, and compare accuracy (vendor, amount, tax, category), cost per document and speed. Set a **hard spending cap and a budget alert before the run** (remember the earlier overspend). Do **not** move AI into the app with client-side Firebase AI Logic: it would put the model call and keys on the phone and bypass our approval step.

**Rules:** no secrets in repo files or this inbox (the repos are pushed to GitHub automatically). Do not deploy; tell Kamyar when the release build test passes.

**Prompt to paste into your Claude**
> Review the Android release setup in the va-mobile repo for Google Play's January 27, 2027 location rule and February 2027 app quality requirement. Read app.json, android/app/build.gradle, android/gradle.properties, plugins/withRemovedPermissions.js and services/location.ts first. (1) Enable R8 minification and resource shrinking for release builds using the expo-build-properties plugin and add keep rules only where a library needs them. (2) Reduce location to approximate or one-time use, or remove it, and list the Data Safety changes. (3) Audit SYSTEM_ALERT_WINDOW, READ_EXTERNAL_STORAGE and WRITE_EXTERNAL_STORAGE and remove any we do not use. Build a release APK or AAB and list what to test on a device (login, voice recording, photo capture, upload, subscription purchase). Do not deploy and do not publish. Write findings to inbox_kamyar.md.

**Please reply** in `inbox_kamyar.md` with what you changed, the release-build test result, and the Argon test result if you run it.
