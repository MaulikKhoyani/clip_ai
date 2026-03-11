# ClipAI - Third-Party Services Setup Guide

This document covers the exact steps to create accounts, configure projects, and obtain all API keys needed for ClipAI. Follow these in order -- some services depend on others.

---

## Service Dependency Order

```mermaid
graph TD
  AppleDev[1. Apple Developer Account] --> Firebase[3. Firebase Project]
  GooglePlay[2. Google Play Developer Account] --> Firebase
  Firebase --> RevenueCat[5. RevenueCat]
  Supabase[4. Supabase Project] --> EdgeFn[4b. Supabase Edge Functions]
  RevenueCat --> EdgeFn
  Banuba[6. Banuba SDK] --> Code[7. Start Coding]
  EdgeFn --> Code
  Firebase --> Code
```

---

## 1. Apple Developer Account

**Cost:** $99/year
**Why needed:** iOS builds, Apple Sign-In, App Store subscription products, TestFlight
**Time:** 5 minutes to apply, 24-48 hours for Apple to approve

### Steps:

1. Go to [developer.apple.com/programs](https://developer.apple.com/programs/)
2. Click **"Enroll"**
3. Sign in with your Apple ID (or create one)
4. Choose **"Individual"** enrollment (unless you have a company)
5. Fill in your legal name, address, phone number
6. Pay $99 USD
7. Wait for approval (usually 24-48 hours, sometimes instant)

### After Approval - Create App ID:

1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** in the left sidebar
4. Click the **"+"** button
5. Select **"App IDs"** -> Continue
6. Select **"App"** -> Continue
7. Fill in:
   - **Description:** `ClipAI`
   - **Bundle ID:** Select "Explicit" and enter `com.clipai.clipai`
8. Scroll down to **Capabilities** and enable:
   - **Sign In with Apple** (check the box)
   - **In-App Purchase** (check the box)
   - **Push Notifications** (check the box)
9. Click **Continue** -> **Register**

### Create App in App Store Connect:

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **"My Apps"**
3. Click the **"+"** button -> **"New App"**
4. Fill in:
   - **Platforms:** iOS
   - **Name:** `ClipAI`
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select `com.clipai.clipai` (created above)
   - **SKU:** `clipai-ios-001`
   - **User Access:** Full Access
5. Click **Create**

### Create Subscription Products (for RevenueCat later):

1. In App Store Connect -> your ClipAI app
2. Click **"Subscriptions"** in the left sidebar under Features
3. Click **"+"** next to "Subscription Groups"
4. Create group name: `ClipAI Pro`
5. Click **"Create"** inside the group to add subscriptions:

**Subscription 1 - Monthly:**
- Reference Name: `ClipAI Pro Monthly`
- Product ID: `clipai_pro_monthly`
- Subscription Duration: 1 Month
- Subscription Price: $9.99
- Add localization (display name + description shown to users)

**Subscription 2 - Yearly:**
- Reference Name: `ClipAI Pro Yearly`
- Product ID: `clipai_pro_yearly`
- Subscription Duration: 1 Year
- Subscription Price: $59.99
- Add localization

6. For Lifetime purchase, go to **"In-App Purchases"** (not Subscriptions)
7. Click **"+"**
   - Type: **Non-Consumable**
   - Reference Name: `ClipAI Pro Lifetime`
   - Product ID: `clipai_pro_lifetime`
   - Price: $99.99
   - Add localization

### Generate Apple Sign-In Service ID & Key:

1. Go to **Certificates, Identifiers & Profiles** -> **Identifiers**
2. Click **"+"** -> Select **"Services IDs"** -> Continue
3. Fill in:
   - Description: `ClipAI Sign In`
   - Identifier: `com.clipai.clipai.signin`
4. Click **Continue** -> **Register**
5. Click on the newly created service ID
6. Enable **"Sign In with Apple"**
7. Click **Configure** next to it
8. Primary App ID: Select `ClipAI (com.clipai.clipai)`
9. Add your Supabase callback URL (you'll get this from Supabase later):
   - `https://YOUR_SUPABASE_PROJECT.supabase.co/auth/v1/callback`
10. Click **Save** -> **Continue** -> **Save**

Now create the **Key** for Apple Sign-In:

1. Go to **Keys** in the left sidebar
2. Click **"+"**
3. Key Name: `ClipAI Auth Key`
4. Check **"Sign in with Apple"**
5. Click **Configure** -> Select `ClipAI` as Primary App ID -> Save
6. Click **Continue** -> **Register**
7. **DOWNLOAD THE KEY FILE (.p8)** - You can only download this ONCE
8. Note down:
   - **Key ID** (shown on the page, e.g., `ABC123DEFG`)
   - **Team ID** (found at top right of developer portal, e.g., `TEAM1234`)

**Save these values - you'll need them for Supabase Apple Auth configuration.**

---

## 2. Google Play Developer Account

**Cost:** $25 one-time
**Why needed:** Android release, Google Play subscription products, Google Sign-In
**Time:** 5 minutes to apply, 24-48 hours for Google to verify

### Steps:

1. Go to [play.google.com/console/signup](https://play.google.com/console/signup)
2. Sign in with your Google account
3. Accept the Developer Distribution Agreement
4. Pay $25 registration fee
5. Fill in developer profile (name, email, website, phone)
6. Complete identity verification (may require government ID)
7. Wait for approval

### After Approval - Create App:

1. Go to [play.google.com/console](https://play.google.com/console)
2. Click **"Create app"**
3. Fill in:
   - **App name:** `ClipAI`
   - **Default language:** English (United States)
   - **App or Game:** App
   - **Free or Paid:** Free
4. Check all declarations -> Click **"Create app"**

### Create Subscription Products (for RevenueCat later):

1. In Google Play Console -> ClipAI app
2. Left sidebar -> **Monetize** -> **Products** -> **Subscriptions**
3. Click **"Create subscription"**

**Subscription 1 - Monthly:**
- Product ID: `clipai_pro_monthly`
- Name: `ClipAI Pro Monthly`
- Add a base plan:
  - Base plan ID: `monthly-plan`
  - Renewal type: Auto-renewing
  - Billing period: 1 Month
  - Price: $9.99

**Subscription 2 - Yearly:**
- Product ID: `clipai_pro_yearly`
- Name: `ClipAI Pro Yearly`
- Add a base plan:
  - Base plan ID: `yearly-plan`
  - Renewal type: Auto-renewing
  - Billing period: 1 Year
  - Price: $59.99

4. For Lifetime, go to **In-app products** (One-time products)
5. Click **"Create product"**
   - Product ID: `clipai_pro_lifetime`
   - Name: `ClipAI Pro Lifetime`
   - Price: $99.99

### Set Up Google Sign-In (OAuth):

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Select or create a project (Firebase will auto-create one - use that one after Step 3)
3. Navigate to **APIs & Services** -> **OAuth consent screen**
4. Select **External** -> Create
5. Fill in:
   - App name: `ClipAI`
   - User support email: your email
   - Developer contact: your email
6. Click **Save and Continue** through all steps
7. Navigate to **APIs & Services** -> **Credentials**
8. Click **"+ CREATE CREDENTIALS"** -> **"OAuth client ID"**
9. For **Android:**
   - Application type: Android
   - Name: `ClipAI Android`
   - Package name: `com.clipai.clipai`
   - SHA-1 fingerprint: (get this by running the command below)
10. For **iOS:**
    - Application type: iOS
    - Name: `ClipAI iOS`
    - Bundle ID: `com.clipai.clipai`

**To get SHA-1 fingerprint (run in terminal):**

```bash
cd android && ./gradlew signingReport
```

Or for debug keystore:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Note the **Client ID** for both Android and iOS - needed for `google_sign_in` Flutter package.

---

## 3. Firebase Project

**Cost:** Free (Spark plan is sufficient for MVP)
**Why needed:** Analytics, Crashlytics, Push Notifications (FCM)
**Time:** 15-20 minutes
**Prerequisite:** Google account

### Create Firebase Project:

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **"Create a project"** (or "Add project")
3. Project name: `ClipAI`
4. **Enable Google Analytics** -> Toggle ON
5. Select or create a Google Analytics account -> `ClipAI`
6. Click **Create project**
7. Wait for it to be ready -> Click **Continue**

### Add Android App:

1. On Firebase project dashboard, click the **Android icon**
2. Fill in:
   - Android package name: `com.clipai.clipai`
   - App nickname: `ClipAI Android`
   - Debug signing certificate SHA-1: (same SHA-1 from Google Sign-In step above)
3. Click **Register app**
4. **Download `google-services.json`**
5. Place it at: `android/app/google-services.json` in your Flutter project
6. Click **Next** through remaining steps (we'll add SDK dependencies in code)

### Add iOS App:

1. On Firebase dashboard, click **"+ Add app"** -> select **iOS icon**
2. Fill in:
   - iOS bundle ID: `com.clipai.clipai`
   - App nickname: `ClipAI iOS`
   - App Store ID: (leave blank for now)
3. Click **Register app**
4. **Download `GoogleService-Info.plist`**
5. Place it at: `ios/Runner/GoogleService-Info.plist` in your Flutter project
6. Click **Next** through remaining steps

### Enable Crashlytics:

1. In Firebase Console left sidebar -> **Crashlytics**
2. Click **Enable Crashlytics**
3. Select your Android app -> It will wait for a crash report (that's fine, it activates after first app run)
4. Repeat for iOS app

### Enable Cloud Messaging (FCM):

1. In left sidebar -> **Cloud Messaging**
2. It should be auto-enabled with your project
3. For iOS, you need an **APNs Key:**
   - Go to [developer.apple.com](https://developer.apple.com) -> Certificates, Identifiers & Profiles -> **Keys**
   - Create a new key with **Apple Push Notifications service (APNs)** enabled
   - Download the `.p8` key file
   - In Firebase -> Project Settings -> **Cloud Messaging** tab
   - Under iOS app -> click **Upload** next to APNs Authentication Key
   - Upload the `.p8` file, enter Key ID and Team ID

### Install FlutterFire CLI (for auto-configuration):

Run this in your terminal after creating the Flutter project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```

This auto-generates `lib/firebase_options.dart` with all platform configurations.

---

## 4. Supabase Project

**Cost:** Free tier (generous for MVP: 50K MAU, 500MB DB, 1GB storage)
**Why needed:** Auth, Database, File Storage, Edge Functions
**Time:** 15-20 minutes
**Prerequisite:** GitHub or email account

### Create Supabase Project:

1. Go to [supabase.com](https://supabase.com) -> Click **"Start your project"**
2. Sign in with GitHub (recommended) or email
3. Click **"New project"**
4. Fill in:
   - Organization: Create one or use existing
   - Project name: `clipai`
   - Database password: **Generate a strong password and SAVE IT**
   - Region: Choose the closest to your target users
   - Pricing plan: Free (upgrade later when needed)
5. Click **"Create new project"**
6. Wait 2-3 minutes for provisioning

### Get Your API Keys:

1. Go to **Project Settings** (gear icon) -> **API**
2. Note down these values:

| Key                  | Where to Find                           | What It's For                                        |
| -------------------- | --------------------------------------- | ---------------------------------------------------- |
| **Project URL**      | Under "Project URL"                     | `https://xxxxx.supabase.co` - used in Flutter app    |
| **anon public key**  | Under "Project API keys"                | Public key safe for client-side, used in Flutter app |
| **service_role key** | Under "Project API keys" (click reveal) | NEVER put in client code - only for Edge Functions   |

### Configure Authentication Providers:

**A. Email/Password (enabled by default):**

1. Go to **Authentication** -> **Providers**
2. **Email** should already be enabled
3. Recommended settings:
   - Enable email confirmations: **OFF** for development, **ON** for production
   - Minimum password length: **8**

**B. Google OAuth:**

1. Go to **Authentication** -> **Providers** -> **Google**
2. Toggle **Enable**
3. Fill in:
   - **Client ID:** Use the **Web client ID** from Google Cloud Console
   - **Client Secret:** From the same OAuth credential
4. Copy the **Callback URL** shown by Supabase
5. Go back to Google Cloud Console -> add this callback URL to **Authorized redirect URIs**
6. Click **Save** in both places

**C. Apple OAuth:**

1. Go to **Authentication** -> **Providers** -> **Apple**
2. Toggle **Enable**
3. Fill in:
   - **Client ID:** `com.clipai.clipai.signin` (the Service ID from Apple Developer step)
   - **Secret Key:** Paste the contents of the `.p8` file you downloaded
   - **Key ID:** The Key ID from Apple Developer
   - **Team ID:** Your Apple Developer Team ID
4. Copy the **Callback URL** shown by Supabase
5. Go back to Apple Developer -> add the Supabase callback URL to **Return URLs**
6. Click **Save** in both places

### Run Database Schema:

1. Go to **SQL Editor** in left sidebar
2. Click **"New query"**
3. Copy and paste the **entire SQL schema from the TRD document** (Section 4.1)
4. Click **"Run"**
5. Verify tables were created in **Table Editor**

### Run RLS Policies:

1. In SQL Editor, create a **new query**
2. Copy and paste the **entire RLS policy SQL from the TRD document** (Section 4.2)
3. Click **"Run"**

### Create Storage Buckets:

1. Go to **Storage** in left sidebar
2. Create three buckets:
   - `avatars` (Public, 2 MB limit)
   - `thumbnails` (Private, 5 MB limit)
   - `template-assets` (Public, 50 MB limit)
3. Run storage RLS policies from TRD Section 4.3

---

## 5. RevenueCat Account

**Cost:** Free up to $2,500/month tracked revenue
**Why needed:** Manages subscriptions across App Store and Google Play from one API
**Time:** 20-30 minutes
**Prerequisite:** Apple Developer + Google Play accounts, products created

### Create Account:

1. Go to [app.revenuecat.com/signup](https://app.revenuecat.com/signup)
2. Sign up with email or GitHub
3. Create a new project: `ClipAI`

### Add Platform - Apple App Store:

1. In RevenueCat dashboard -> **Project Settings** -> **Apps**
2. Click **"+ New"** -> Select **"App Store"**
3. Fill in: App name, Bundle ID, App-Specific Shared Secret
4. Note the **Public API Key** (starts with `appl_...`)

### Add Platform - Google Play Store:

1. Click **"+ New"** -> Select **"Play Store"**
2. Fill in: App name, Package name, Service Account Credentials JSON
3. Note the **Public API Key** (starts with `goog_...`)

### Configure Entitlements:

1. Go to **Entitlements** -> Click **"+ New"**
   - Identifier: `pro_access`
   - Description: `ClipAI Pro access - all premium features`

### Configure Products:

| App Store Product ID  | Play Store Product ID             | Identifier            |
| --------------------- | --------------------------------- | --------------------- |
| `clipai_pro_monthly`  | `clipai_pro_monthly:monthly-plan` | `clipai_pro_monthly`  |
| `clipai_pro_yearly`   | `clipai_pro_yearly:yearly-plan`   | `clipai_pro_yearly`   |
| `clipai_pro_lifetime` | `clipai_pro_lifetime`             | `clipai_pro_lifetime` |

Attach each product to the `pro_access` entitlement.

### Configure Offerings:

1. Go to **Offerings** -> Use "Default" offering
2. Add 3 packages: `$rc_monthly`, `$rc_annual`, `$rc_lifetime`
3. Set as **Current**

### Set Up Webhook to Supabase:

1. Go to **Project Settings** -> **Integrations** -> **Webhooks**
2. Webhook URL: `https://YOUR_SUPABASE_PROJECT.supabase.co/functions/v1/validate-subscription`
3. Authorization: `Bearer YOUR_CUSTOM_WEBHOOK_SECRET`
4. Select all events

---

## 6. Banuba Video Editor SDK

**Cost:** Free 14-day trial, then custom pricing
**Time:** 5 minutes

### Get License Token:

1. Go to [banuba.com/video-editor-sdk#form](https://www.banuba.com/video-editor-sdk#form)
2. Fill in the form (Name, Email, Platform: Flutter)
3. You will receive an email with the **License token**
4. Save the license token for `ApiConstants.banubaLicenseToken`

---

## 7. Deploy Supabase Edge Function

### Install Supabase CLI:

```bash
brew install supabase/tap/supabase
```

### Login and Link:

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

### Set Secrets:

```bash
supabase secrets set REVENUECAT_WEBHOOK_SECRET=your_webhook_secret_here
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```

### Deploy:

```bash
supabase functions deploy validate-subscription
```

---

## 8. Master Credentials Checklist

| #   | Credential                     | Where to Put in Code                         | Status |
| --- | ------------------------------ | -------------------------------------------- | ------ |
| 1   | Supabase Project URL           | `ApiConstants.supabaseUrl`                   | [ ]    |
| 2   | Supabase Anon Key              | `ApiConstants.supabaseAnonKey`               | [ ]    |
| 3   | Supabase Service Role Key      | Supabase Edge Function secrets only          | [ ]    |
| 4   | Banuba License Token           | `ApiConstants.banubaLicenseToken`            | [ ]    |
| 5   | RevenueCat iOS API Key         | `ApiConstants.revenueCatAppleKey`            | [ ]    |
| 6   | RevenueCat Android API Key     | `ApiConstants.revenueCatGoogleKey`           | [ ]    |
| 7   | RevenueCat Webhook Secret      | Supabase Edge Function secret                | [ ]    |
| 8   | Firebase Android config        | `android/app/google-services.json` (file)    | [ ]    |
| 9   | Firebase iOS config            | `ios/Runner/GoogleService-Info.plist` (file) | [ ]    |
| 10  | Google OAuth Web Client ID     | Supabase Google Auth provider config         | [ ]    |
| 11  | Google OAuth Web Client Secret | Supabase Google Auth provider config         | [ ]    |
| 12  | Apple Auth Key ID              | Supabase Apple Auth provider config          | [ ]    |
| 13  | Apple Auth Team ID             | Supabase Apple Auth provider config          | [ ]    |
| 14  | Apple Auth .p8 Key             | Supabase Apple Auth provider config          | [ ]    |
| 15  | Apple Auth Service ID          | Supabase Apple Auth provider config          | [ ]    |

---

## 9. Estimated Time for All Setup

| Service                                   | Time                                 |
| ----------------------------------------- | ------------------------------------ |
| Apple Developer Account                   | 5 min signup + 24-48 hr approval     |
| Google Play Developer Account             | 5 min signup + 24-48 hr approval     |
| Firebase Project + both platforms         | 15-20 min                            |
| Supabase Project + schema + RLS + storage | 20-30 min                            |
| RevenueCat + products + webhook           | 20-30 min                            |
| Banuba SDK trial                          | 5 min                                |
| **Total active work**                     | **~1.5 hours**                       |
| **Total including wait times**            | **1-2 days (Apple/Google approval)** |

**Tip:** Start with Apple and Google developer account registrations first since they have approval wait times. While waiting, set up Firebase, Supabase, and Banuba.
