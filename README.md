# ClipAI — AI-Powered Short-Form Video Editor

ClipAI is a production-ready Flutter mobile application for creating, editing, and exporting short-form videos powered by the **IMG.LY Video Editor SDK** (integrated via Flutter Platform Channels). It supports user authentication via Supabase, in-app subscriptions via RevenueCat, push notifications via Firebase Cloud Messaging, and crash/analytics reporting via Firebase.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [Architecture](#3-architecture)
4. [Project Structure](#4-project-structure)
5. [Screens & Features](#5-screens--features)
6. [Services](#6-services)
7. [Data Layer](#7-data-layer)
8. [Domain Layer](#8-domain-layer)
9. [State Management (BLoC)](#9-state-management-bloc)
10. [Navigation (GoRouter)](#10-navigation-gorouter)
11. [Dependency Injection (GetIt)](#11-dependency-injection-getit)
12. [Theming & Design System](#12-theming--design-system)
13. [Subscription & Monetization](#13-subscription--monetization)
14. [Push Notifications](#14-push-notifications)
15. [Analytics & Crash Reporting](#15-analytics--crash-reporting)
16. [Local Storage (Hive)](#16-local-storage-hive)
17. [Environment Setup & API Keys](#17-environment-setup--api-keys)
18. [How to Run](#18-how-to-run)
19. [IMG.LY Platform Channel Architecture](#19-imgly-platform-channel-architecture)
20. [Supabase Database Schema](#20-supabase-database-schema)
21. [Free vs Pro Features](#21-free-vs-pro-features)
22. [Asset Structure](#22-asset-structure)
23. [Error Handling](#23-error-handling)
24. [Key Files Quick Reference](#24-key-files-quick-reference)

---

## 1. Project Overview

ClipAI lets users:

- **Record or import** videos directly from the camera or device gallery
- **Edit** using the full IMG.LY Video Editor SDK (effects, audio, filters, color grading, text, stickers)
- **Use AI features** including AI Clipping, Background Removal, Auto-Captions (ElevenLabs Scribe)
- **Apply templates** to create professional short-form content instantly
- **Export** at 720p (free) or 1080p (Pro), with or without a watermark
- **Manage projects** synced to Supabase cloud storage
- **Upgrade to Pro** via monthly, yearly, or lifetime subscriptions managed by RevenueCat

The app targets portrait orientation only and uses a dark-mode-only design.

---

## 2. Tech Stack

| Category | Package / SDK | Version |
|---|---|---|
| Language | Dart / Flutter | SDK ^3.10.4 |
| State Management | flutter_bloc + equatable | ^9.1.0 / ^2.0.7 |
| Navigation | go_router | ^14.8.1 |
| Backend / Auth | supabase_flutter | ^2.9.0 |
| Video Editor SDK | IMG.LY VE.SDK (platform channel) | Android 10.7.0 / iOS ~10.0 |
| Subscriptions | purchases_flutter (RevenueCat) | ^8.6.0 |
| Firebase Analytics | firebase_analytics | ^11.5.0 |
| Firebase Crashlytics | firebase_crashlytics | ^4.3.0 |
| Push Notifications | firebase_messaging + flutter_local_notifications | ^15.2.4 / ^18.0.1 |
| Dependency Injection | get_it | ^8.0.3 |
| Local Storage | hive_flutter | ^1.1.0 |
| Fonts | google_fonts (Inter) | ^6.2.1 |
| UI Icons | iconsax_flutter | ^1.0.0+1 |
| Image Loading | cached_network_image | ^3.4.1 |
| Loading Skeletons | shimmer | ^3.0.0 |
| Page Indicator | smooth_page_indicator | ^1.2.0+3 |
| SVG Support | flutter_svg | ^2.0.17 |
| Share | share_plus | ^10.1.4 |
| Image Picker | image_picker | ^1.1.2 |
| Save to Gallery | gallery_saver_plus | ^3.2.5 |
| Permissions | permission_handler | ^11.4.0 |
| URL Launcher | url_launcher | ^6.3.1 |
| UUID | uuid | ^4.5.1 |
| Internationalization | intl | ^0.20.2 |
| Path Provider | path_provider | ^2.1.5 |

---

## 3. Architecture

The project follows **Clean Architecture** split into three layers:

```
Presentation Layer   <-->   Domain Layer   <-->   Data Layer
  (BLoC / UI)             (Entities +           (Repositories +
                          Repositories            DataSources +
                           Interfaces)              Models)
```

### Layer Responsibilities

**Presentation Layer** (`lib/presentation/`)
- Flutter Widgets (Screens)
- BLoC (Business Logic Components) that emit UI states
- Depends only on Domain layer abstractions

**Domain Layer** (`lib/domain/`)
- Pure Dart entities (no Flutter, no external packages except equatable)
- Repository interfaces (abstract classes)
- Business rules (e.g. Pro/Free feature gates)

**Data Layer** (`lib/data/`)
- Repository implementations
- Data models (JSON serialization)
- Data sources: `SupabaseDataSource` (remote), `LocalDataSource` (Hive)

### Data Flow

```
UI Event -> BLoC -> Repository Interface -> Repository Impl -> DataSource -> Supabase/Hive
                                                            |
UI State <- BLoC <- Repository Interface <- Result<Entity> <- Model.toEntity()
```

### Result Type

All repository methods return a sealed `Result<T>` type:

```dart
// lib/core/errors/result.dart
sealed class Result<T> { ... }
class Success<T> extends Result<T> { final T value; }
class Failure<T> extends Result<T> { final AppException exception; }

// Usage
final result = await repository.getProjects(userId);
result.when(
  success: (projects) => emit(ProjectsLoaded(projects)),
  failure: (e) => emit(ProjectsError(e.message)),
);
```

---

## 4. Project Structure

```
clip_ai/
├── lib/
│   ├── main.dart                        # App entry point, initializations
│   ├── app.dart                         # ClipAiApp widget, theme, router
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart       # Supabase URL, IMG.LY key, RevenueCat keys
│   │   │   ├── app_colors.dart          # All color definitions
│   │   │   ├── app_strings.dart         # All UI strings (no hardcoding)
│   │   │   └── app_assets.dart          # Asset path constants
│   │   ├── di/
│   │   │   └── injection.dart           # GetIt dependency registration
│   │   ├── errors/
│   │   │   ├── app_exceptions.dart      # Typed exception classes
│   │   │   └── result.dart              # Result<T> sealed class
│   │   ├── observers/
│   │   │   └── crashlytics_bloc_observer.dart  # BLoC error -> Crashlytics
│   │   ├── routing/
│   │   │   └── app_router.dart          # GoRouter config + MainShell
│   │   ├── theme/
│   │   │   └── app_theme.dart           # Material 3 dark theme
│   │   ├── utils/
│   │   │   └── extensions.dart          # Dart extension methods
│   │   └── firebase_options.dart        # Generated Firebase config
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── user_entity.dart
│   │   │   ├── project_entity.dart
│   │   │   ├── template_entity.dart
│   │   │   └── export_entity.dart
│   │   └── repositories/
│   │       ├── auth_repository.dart
│   │       ├── project_repository.dart
│   │       ├── template_repository.dart
│   │       └── export_repository.dart
│   │
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── supabase_datasource.dart # All Supabase API calls
│   │   │   └── local_datasource.dart    # Hive read/write
│   │   ├── models/
│   │   │   ├── user_model.dart          # fromJson / toEntity
│   │   │   ├── project_model.dart
│   │   │   ├── template_model.dart
│   │   │   └── export_model.dart
│   │   └── repositories/
│   │       ├── auth_repository_impl.dart
│   │       ├── project_repository_impl.dart
│   │       ├── template_repository_impl.dart
│   │       └── export_repository_impl.dart
│   │
│   ├── presentation/
│   │   ├── splash/          splash_screen.dart
│   │   ├── onboarding/      onboarding_screen.dart
│   │   ├── auth/            auth_screen.dart + bloc/
│   │   ├── home/            home_screen.dart + bloc/
│   │   ├── templates/       templates_screen.dart + bloc/
│   │   ├── projects/        projects_screen.dart + bloc/
│   │   ├── editor/          editor_screen.dart
│   │   ├── export/          export_screen.dart + bloc/
│   │   ├── paywall/         paywall_screen.dart
│   │   ├── settings/        settings_screen.dart
│   │   └── notifications/   notification_settings_screen.dart
│   │
│   └── services/
│       ├── imgly_service.dart           # IMG.LY platform channel wrapper
│       ├── subscription_service.dart    # RevenueCat wrapper
│       ├── analytics_service.dart       # Firebase Analytics + Crashlytics
│       └── notification_service.dart    # FCM + local notifications
│
├── android/
│   ├── app/src/main/kotlin/.../
│   │   └── MainActivity.kt             # IMG.LY MethodChannel handler (Android)
│   ├── app/build.gradle.kts            # IMG.LY SDK dependency
│   └── build.gradle.kts                # IMG.LY Maven repository
│
├── ios/
│   ├── Runner/
│   │   ├── AppDelegate.swift            # IMG.LY MethodChannel handler (iOS)
│   │   └── imgly.license               # IMG.LY license file (add in Xcode)
│   └── Podfile                         # VideoEditorSDK pod
│
├── assets/
│   ├── images/              # App images (PNG/JPG)
│   ├── icons/               # Custom icons (SVG/PNG)
│   ├── lottie/              # Lottie animations
│   └── watermark/           # clipai_watermark.png (applied on free exports)
│
└── pubspec.yaml
```

---

## 5. Screens & Features

### Splash Screen (`/`)
- Shown on app launch
- Checks onboarding completion and auth state
- Redirects to onboarding, auth, or home automatically

### Onboarding Screen (`/onboarding`)
- Shown once on first launch
- Walks the user through app features
- Saves `onboarding_completed = true` to Hive on completion

### Auth Screen (`/auth`)
- Email + password sign-up and sign-in via Supabase Auth
- Google OAuth (if configured)
- On successful login, creates or fetches user profile from Supabase `profiles` table
- Triggers FCM token upload and RevenueCat login

### Home Screen (`/home`)
- Personalized greeting with user's display name
- **Quick Actions**: Record Video and Import Video buttons (both open the IMG.LY editor)
- **Featured Templates**: Horizontal scroll of top templates by download count
- **Recent Projects**: Latest 5 projects with status (Draft/Exported) and duration
- PRO badge shown on user avatar if subscription is active
- Shimmer loading state while data fetches
- Pull-to-refresh
- FAB opens the editor

### Templates Screen (`/templates`)
- Full list of all templates grouped by category
- Pro templates show a lock icon overlay for free users
- Tapping a template opens the IMG.LY editor via platform channel

### Projects Screen (`/projects`)
- All user projects sorted by `updated_at` descending
- Create, view, delete projects
- Status: `draft` or `exported`
- Opens IMG.LY editor for an existing project

### Editor Screen (`/editor`)
- Wrapper around IMG.LY Video Editor SDK via platform channel
- Supports:
  - **Camera** — record directly from camera inside IMG.LY editor
  - **Import** — pick video from gallery, open in IMG.LY editor
  - **AI Clipping** — pick video, open editor with trim tools for manual AI-assisted clipping
  - **Templates** — opens IMG.LY editor (templates available inside)
  - **Drafts** — opens IMG.LY editor (drafts managed internally by SDK)
- Free users: 720p export; Pro users: 1080p export
- On export completion, navigates to Export Screen

### Export Screen (`/export?projectId=&videoPath=`)
- Shows export summary (resolution, format, file size)
- Options: Save to gallery, Share, View in Projects
- Logs export event to Firebase Analytics
- Saves export record to Supabase `exports` table

### Paywall Screen (`/paywall`)
- Shown when a free user tries to access a Pro feature
- Displays Pro feature list:
  - HD Export (1080p)
  - No Watermark
  - All Templates Unlocked
  - Background Removal
  - Advanced AI Captions
  - Priority Support
- 3 plan options: Monthly ($9.99), Yearly ($59.99 — "Best Value" badge), Lifetime ($99.99)
- Plan prices pulled from RevenueCat live offerings
- "Subscribe Now" triggers RevenueCat purchase flow
- "Restore Purchases" for users who previously subscribed

### Settings Screen (`/settings`)
- User profile info
- Subscription status (shows upgrade button for free users)
- Sign out
- Notification settings link
- App version info

### Notification Settings Screen (`/notification-settings`)
- Master on/off toggle for all notifications
- Per-type toggles: Export Complete, New Templates, Promotions
- Preferences saved to Hive `settings` box

---

## 6. Services

### ImglyService (`lib/services/imgly_service.dart`)

Flutter-side platform channel client that communicates with native IMG.LY Video Editor SDK on Android (Kotlin) and iOS (Swift).

**Channel name:** `com.clipai.imgly/editor`

```dart
// Open camera recording
final result = await imglyService.openCamera(isPro: isPro);

// Open editor with existing video
final result = await imglyService.openEditor([videoPath], isPro: isPro);

// AI clipping (editor with video preloaded)
final result = await imglyService.openAiClipping(videoPath);

// Templates / Drafts
final result = await imglyService.openTemplates();
final result = await imglyService.openDrafts();

// Check result
if (result == null) { /* user cancelled */ }
if (result!.isSuccess) { /* exportedVideoPath available */ }
if (result.error != null) { /* handle error */ }
```

**Return value:** `ImglyResult` with `exportedVideoPath` (on success) or `error` (on failure). Returns `null` if the user cancelled.

### SubscriptionService (`lib/services/subscription_service.dart`)
Wraps RevenueCat `purchases_flutter`.

```dart
final isPro = await subscriptionService.isProUser;
bool canExport = subscriptionService.canExportHD(isPro: isPro);
bool canRemoveWatermark = subscriptionService.canRemoveWatermark(isPro: isPro);
bool canAccessAllTemplates = subscriptionService.canAccessAllTemplates(isPro: isPro);
bool canUseBackgroundRemoval = subscriptionService.canUseBackgroundRemoval(isPro: isPro);
```

Entitlement ID: `pro_access`
Free template limit: 3 templates

### AnalyticsService (`lib/services/analytics_service.dart`)
Wraps Firebase Analytics and Crashlytics.

**Events tracked:**
- `app_open`, `onboarding_complete`, `sign_up`, `login`
- `editor_opened` (source: home/templates/projects)
- `template_selected` (template_id, template_name)
- `ai_captions_used`, `bg_removal_used`
- `export_started`, `export_completed`
- `paywall_shown`, `purchase_started`, `purchase_completed`

Crashlytics is enabled only in **release/profile** builds (disabled in debug).

### NotificationService (`lib/services/notification_service.dart`)
Singleton handling Firebase Cloud Messaging + local notifications.

**Notification types supported (via FCM `data.type` field):**

| Type | Hive Key | Default |
|---|---|---|
| `export_complete` | `notif_export_complete` | enabled |
| `new_templates` | `notif_new_templates` | enabled |
| `promotion` | `notif_promotions` | enabled |

FCM token is saved to `profiles.fcm_token` in Supabase on login and on token refresh.

---

## 7. Data Layer

### SupabaseDataSource (`lib/data/datasources/supabase_datasource.dart`)

All remote API calls to Supabase. Methods:

**Profiles:**
- `getProfile(userId)` -> `UserModel`
- `createProfile(data)` -> `UserModel`
- `updateProfile(userId, data)` -> `UserModel`
- `saveFcmToken(userId, token)` — saves FCM token to profile row

**Projects:**
- `getProjects(userId)` -> `List<ProjectModel>` ordered by `updated_at DESC`
- `getProject(id)` -> `ProjectModel`
- `createProject(data)` -> `ProjectModel`
- `updateProject(id, data)` -> `ProjectModel`
- `deleteProject(id)` -> void

**Templates:**
- `getTemplates({category?})` -> `List<TemplateModel>` ordered by `sort_order ASC`
- `getFeaturedTemplates(limit)` -> `List<TemplateModel>` ordered by `download_count DESC`
- `incrementTemplateDownload(id)` — calls Supabase RPC `increment_template_download`

**Exports:**
- `logExport(data)` -> `ExportModel`
- `getExports(userId)` -> `List<ExportModel>` ordered by `exported_at DESC`

### LocalDataSource (`lib/data/datasources/local_datasource.dart`)
Reads and writes to Hive boxes (`settings`, `cache`) for offline-first project caching and user preferences.

---

## 8. Domain Layer

### Entities

**UserEntity**
```dart
String id, email, displayName, avatarUrl, createdAt
```

**ProjectEntity**
```dart
String id, userId, title, status ('draft'|'exported')
String? thumbnailPath, templateId
int? durationSeconds
Map<String, dynamic> projectMeta
DateTime? lastExportedAt, createdAt, updatedAt

// Computed
bool get isDraft
bool get isExported
String get formattedDuration  // "MM:SS"
```

**TemplateEntity**
```dart
String id, name, category, thumbnailUrl, aspectRatio ('9:16')
String? description, previewVideoUrl
Map<String, dynamic> templateData
int? durationSeconds, downloadCount
bool isPro
List<String> tags
```

**ExportEntity**
```dart
String id, userId, projectId, videoPath, resolution, format
double fileSizeMb
int durationSeconds
DateTime exportedAt
```

### Repository Interfaces

Each interface is an abstract class defined in `lib/domain/repositories/`:

```dart
abstract class ProjectRepository {
  Future<Result<List<ProjectEntity>>> getProjects(String userId);
  Future<Result<ProjectEntity>> getProject(String id);
  Future<Result<ProjectEntity>> createProject({...});
  Future<Result<ProjectEntity>> updateProject(String id, {...});
  Future<Result<void>> deleteProject(String id);
}
```

---

## 9. State Management (BLoC)

Each feature has its own BLoC with three files: `*_bloc.dart`, `*_event.dart`, `*_state.dart`.

### AuthBloc

| Event | Action |
|---|---|
| `AuthCheckRequested` | Check current Supabase session |
| `AuthSignUpRequested` | Email sign-up -> create profile |
| `AuthSignInRequested` | Email sign-in |
| `AuthGoogleSignInRequested` | Google OAuth |
| `AuthSignOutRequested` | Sign out + RevenueCat logout |

States: `AuthInitial`, `AuthLoading`, `AuthAuthenticated(user, isPro)`, `AuthUnauthenticated`, `AuthError(message)`

### HomeBloc

| Event | Action |
|---|---|
| `HomeLoadRequested` | Fetch user, featured templates (limit 6), recent projects (limit 5), pro status |
| `HomeRefreshRequested` | Re-fetch all |

States: `HomeInitial`, `HomeLoading`, `HomeLoaded(user, featuredTemplates, recentProjects, isPro)`, `HomeError(message)`

### TemplateBloc

| Event | Action |
|---|---|
| `TemplatesLoadRequested` | Fetch all templates (optionally by category) |
| `TemplateCategoryChanged` | Filter by category |
| `TemplateSelected` | Increment download count, open IMG.LY editor |

States: `TemplatesInitial`, `TemplatesLoading`, `TemplatesLoaded(templates, selectedCategory, isPro)`, `TemplatesError`

### ProjectsBloc

| Event | Action |
|---|---|
| `ProjectsLoadRequested` | Fetch all user projects |
| `ProjectDeleteRequested` | Delete project from Supabase |
| `ProjectCreateRequested` | Create new project record |

States: `ProjectsInitial`, `ProjectsLoading`, `ProjectsLoaded(projects, isPro)`, `ProjectsError`

### ExportBloc

| Event | Action |
|---|---|
| `ExportStarted` | Log export to Supabase, save to gallery, log analytics |

States: `ExportInitial`, `ExportInProgress`, `ExportSuccess(export)`, `ExportError`

---

## 10. Navigation (GoRouter)

Defined in `lib/core/routing/app_router.dart`.

### Route Table

| Path | Screen | Notes |
|---|---|---|
| `/` | SplashScreen | Initial route |
| `/onboarding` | OnboardingScreen | Shown once on first launch |
| `/auth` | AuthScreen | Login / sign-up |
| `/home` | HomeScreen | Main tab (ShellRoute) |
| `/templates` | TemplatesScreen | Main tab (ShellRoute) |
| `/projects` | ProjectsScreen | Main tab (ShellRoute) |
| `/settings` | SettingsScreen | Main tab (ShellRoute) |
| `/editor` | EditorScreen | Full-screen, rootNavigator |
| `/paywall` | PaywallScreen | Full-screen, rootNavigator |
| `/export` | ExportScreen | Full-screen, rootNavigator |
| `/notification-settings` | NotificationSettingsScreen | Full-screen, rootNavigator |

### Redirect Logic

```
On any route except splash:
  1. If onboarding not completed  ->  /onboarding
  2. If not logged in (not on auth route)  ->  /auth
  3. If logged in but on auth route  ->  /home
```

---

## 11. Dependency Injection (GetIt)

All dependencies are registered in `lib/core/di/injection.dart` via `configureDependencies()` called in `main()`.

### Registration Strategy

| Type | Scope | Reason |
|---|---|---|
| `SupabaseClient` | `lazySingleton` | Single Supabase instance |
| `ImglyService` | `lazySingleton` | Platform channel client (stateless) |
| `AnalyticsService` | `singleton` | Initialized eagerly (needs `await`) |
| `NotificationService` | `singleton` | FCM singleton pattern |
| `SubscriptionService` | `lazySingleton` | Stateless wrapper |
| `SupabaseDataSource` | `lazySingleton` | Stateless, one instance fine |
| `LocalDataSource` | `lazySingleton` | Hive is process-wide |
| All Repositories | `lazySingleton` | Stateless data access layer |
| All BLoCs | `factory` | New instance per screen (prevents state leaks) |

---

## 12. Theming & Design System

Theme defined in `lib/core/theme/app_theme.dart`. The app uses **Material 3 dark theme only**.

### Color Palette (`AppColors`)

| Name | Hex | Usage |
|---|---|---|
| `primary` | `#6C5CE7` | Buttons, active states, highlights |
| `primaryLight` | `#8B7CF7` | Hover states |
| `primaryDark` | `#5A4BD1` | Pressed states |
| `accent` | `#00D2FF` | Accent elements, links |
| `backgroundDark` | `#0D0D0D` | App background |
| `surfaceDark` | `#1A1A2E` | Cards, inputs |
| `cardDark` | `#16213E` | Inner cards |
| `textPrimary` | `#FFFFFF` | Main text |
| `textSecondary` | `#B0B0B0` | Subtitles |
| `textTertiary` | `#6C6C6C` | Hints, disabled |
| `success` | `#00E676` | Export complete, success states |
| `error` | `#FF5252` | Error states |
| `proBadge` | `#FFD700` | PRO badge |

Primary gradient: `#6C5CE7` (purple) -> `#00D2FF` (cyan), top-left to bottom-right.

### Typography
Inter font (Google Fonts) used throughout. Scale: `headlineLarge` (28px bold) down to `bodySmall` (12px).

---

## 13. Subscription & Monetization

### RevenueCat Setup

1. Create a RevenueCat account at [revenuecat.com](https://www.revenuecat.com)
2. Create an app for iOS and Android
3. Set up products in App Store Connect / Google Play Console:
   - `clipai_pro_monthly` — Monthly subscription
   - `clipai_pro_yearly` — Annual subscription
   - `clipai_pro_lifetime` — Lifetime purchase
4. Create an entitlement named `pro_access` in RevenueCat and link all products to it
5. Add your API keys to `lib/core/constants/api_constants.dart`:
   ```dart
   static const revenueCatAppleKey = 'YOUR_REVENUECAT_APPLE_KEY';
   static const revenueCatGoogleKey = 'YOUR_REVENUECAT_GOOGLE_KEY';
   ```

### Feature Gates

| Feature | Free | Pro |
|---|---|---|
| Video export resolution | 720p | 1080p |
| Watermark | Yes (bottom-right) | No |
| Templates | First 3 only | All unlocked |
| Background removal | No | Yes |
| AI Captions (Advanced) | No | Yes |
| Support | Standard | Priority |

---

## 14. Push Notifications

### FCM Payload Format

```json
{
  "notification": {
    "title": "Your export is ready!",
    "body": "Tap to view your exported video."
  },
  "data": {
    "type": "export_complete",
    "route": "/projects"
  }
}
```

**Supported `type` values:** `export_complete`, `new_templates`, `promotion`

**Supported `route` values:** Any valid GoRouter path (e.g. `/projects`, `/templates`)

---

## 15. Analytics & Crash Reporting

### Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add iOS and Android apps to your Firebase project
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place them in:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
5. The generated `lib/core/firebase_options.dart` must match your project

### Crashlytics
- Automatically catches Flutter framework errors via `FlutterError.onError`
- Catches async/platform errors via `PlatformDispatcher.instance.onError`
- Catches all BLoC errors via `CrashlyticsBlocObserver`
- Disabled in debug builds — enabled in production only

---

## 16. Local Storage (Hive)

Two Hive boxes are opened at startup:

### `settings` box

| Key | Type | Default | Description |
|---|---|---|---|
| `onboarding_completed` | bool | false | Whether user has seen onboarding |
| `notif_enabled` | bool | true | Master notification toggle |
| `notif_export_complete` | bool | true | Export complete notifications |
| `notif_new_templates` | bool | true | New templates notifications |
| `notif_promotions` | bool | true | Promotional notifications |
| `pending_notification_route` | String? | null | Route to navigate to from cold-start FCM tap |

### `cache` box
Used by `LocalDataSource` for offline caching of projects and other frequently accessed data.

---

## 17. Environment Setup & API Keys

All API keys live in `lib/core/constants/api_constants.dart`.

> **Important:** Never commit real keys to a public repository.

```dart
class ApiConstants {
  // Supabase
  static const supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // IMG.LY Video Editor SDK
  // Android key goes in: android/app/src/main/kotlin/.../MainActivity.kt
  // iOS license file: ios/Runner/imgly.license (add in Xcode)
  static const imglyLicenseKey = 'YOUR_IMGLY_LICENSE_KEY';

  // RevenueCat
  static const revenueCatAppleKey = 'YOUR_REVENUECAT_APPLE_KEY';
  static const revenueCatGoogleKey = 'YOUR_REVENUECAT_GOOGLE_KEY';
  static const entitlementId = 'pro_access';

  // Product IDs (must match App Store Connect / Google Play)
  static const proMonthlyId = 'clipai_pro_monthly';
  static const proYearlyId = 'clipai_pro_yearly';
  static const proLifetimeId = 'clipai_pro_lifetime';
}
```

### Getting an IMG.LY License Key
1. Go to [img.ly](https://img.ly) and request a free trial or purchase a license
2. From your IMG.LY dashboard, download your `imgly.license` file
3. **Android:** Copy the license string into `IMGLY_LICENSE_KEY` in `MainActivity.kt`
4. **iOS:** Add the `imgly.license` file to `ios/Runner/` in Xcode (check "Copy items if needed" and add to the Runner target)

---

## 18. How to Run

### Prerequisites

- Flutter SDK `>=3.10.4` installed
- Xcode (for iOS) or Android Studio (for Android)
- A Supabase project created and configured
- Firebase project with `google-services.json` and `GoogleService-Info.plist`
- IMG.LY license key from [img.ly/dashboard](https://img.ly)

### Steps

```bash
# 1. Clone the repository
git clone <repo-url>
cd clip_ai

# 2. Install Flutter dependencies
flutter pub get

# 3. Fill in your API keys
# Edit: lib/core/constants/api_constants.dart
# Edit: android/app/src/main/kotlin/.../MainActivity.kt  (IMGLY_LICENSE_KEY)
# Add:  ios/Runner/imgly.license  (via Xcode)

# 4. Add Firebase config files
# Android: android/app/google-services.json
# iOS:     ios/Runner/GoogleService-Info.plist

# 5. Install iOS pods
cd ios && pod install && cd ..

# 6. Run on a device or emulator
flutter run

# 7. Build for production
flutter build apk --release    # Android
flutter build ipa --release    # iOS
```

### Android Additional Setup
The IMG.LY Maven repository is already added to `android/build.gradle.kts`:
```kotlin
maven { url = uri("https://artifactory.img.ly/artifactory/imgly") }
```
The IMG.LY SDK dependency is already added to `android/app/build.gradle.kts`:
```kotlin
implementation("ly.img.android.sdk:video-editor-ui:10.7.0")
```

### iOS Additional Setup
The `VideoEditorSDK` pod is already added to `ios/Podfile`.
After running `pod install`, add your `imgly.license` file to the Xcode project:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Drag `imgly.license` into the Runner group
3. Check "Copy items if needed" and ensure Runner target is checked

Ensure the following permissions are in `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>ClipAI needs camera access to record videos</string>
<key>NSMicrophoneUsageDescription</key>
<string>ClipAI needs microphone access to record audio</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>ClipAI needs photo library access to import and export videos</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>ClipAI needs permission to save exported videos to your photo library</string>
```

---

## 19. IMG.LY Platform Channel Architecture

Since IMG.LY CE.SDK does not have an official Flutter package, ClipAI integrates it via **Flutter Platform Channels** — a standard Flutter mechanism for calling native Android/iOS code from Dart.

### How It Works

```
Flutter (Dart)                      Native (Kotlin / Swift)
─────────────────                   ─────────────────────────────────
ImglyService                        MainActivity.kt / AppDelegate.swift
    │                                       │
    │  MethodChannel('com.clipai.imgly/editor')
    │ ─────── invokeMethod('openVideoEditor', args) ──────>
    │                                       │
    │                                  Opens IMG.LY
    │                                  VideoEditorActivity (Android)
    │                                  VideoEditViewController (iOS)
    │                                       │
    │                                  User edits video
    │                                       │
    │ <─────── result({'exportedVideoPath': '/path/...'}) ──
    │
ImglyResult(exportedVideoPath)
```

### Method Channel API

| Method | Args | Returns |
|---|---|---|
| `openVideoEditor` | `videoPaths: List<String>`, `isPro: bool` | `{exportedVideoPath: String}` or `null` (cancelled) |
| `openCamera` | `isPro: bool` | `{exportedVideoPath: String}` or `null` |
| `openAiClipping` | `videoPath: String` | `{exportedVideoPath: String}` or `null` |
| `openTemplates` | — | `{exportedVideoPath: String}` or `null` |
| `openDrafts` | — | `{exportedVideoPath: String}` or `null` |

On error, returns `{error: String}`.

### Key Files

| File | Role |
|---|---|
| `lib/services/imgly_service.dart` | Dart MethodChannel client |
| `android/.../MainActivity.kt` | Android native handler + IMG.LY integration |
| `ios/Runner/AppDelegate.swift` | iOS native handler + IMG.LY integration |

---

## 20. Supabase Database Schema

Run these SQL statements in your Supabase SQL editor to set up the full database:

```sql
-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Profiles table (extends Supabase auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  display_name text,
  avatar_url text,
  fcm_token text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.profiles enable row level security;
create policy "Users can view their own profile" on public.profiles
  for select using (auth.uid() = id);
create policy "Users can update their own profile" on public.profiles
  for update using (auth.uid() = id);

-- Projects table
create table public.projects (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  thumbnail_path text,
  duration_seconds integer,
  template_id uuid,
  project_meta jsonb default '{}',
  status text default 'draft' check (status in ('draft', 'exported')),
  last_exported_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.projects enable row level security;
create policy "Users can manage their own projects" on public.projects
  using (auth.uid() = user_id);

-- Templates table (admin-managed)
create table public.templates (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  description text,
  category text not null,
  thumbnail_url text not null,
  preview_video_url text,
  template_data jsonb default '{}',
  aspect_ratio text default '9:16',
  duration_seconds integer,
  is_pro boolean default false,
  download_count integer default 0,
  tags text[] default '{}',
  sort_order integer default 0,
  created_at timestamptz default now()
);
alter table public.templates enable row level security;
create policy "Templates are viewable by everyone" on public.templates
  for select using (true);

-- RPC to safely increment download count
create or replace function increment_template_download(t_id uuid)
returns void language sql as $$
  update public.templates set download_count = download_count + 1 where id = t_id;
$$;

-- Exports table
create table public.exports (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  project_id uuid references public.projects(id) on delete set null,
  video_path text,
  resolution text,
  format text,
  file_size_mb double precision,
  duration_seconds integer,
  exported_at timestamptz default now()
);
alter table public.exports enable row level security;
create policy "Users can manage their own exports" on public.exports
  using (auth.uid() = user_id);

-- Auto-create profile on sign-up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
```

---

## 21. Free vs Pro Features

| Feature | Free | Pro |
|---|---|---|
| Record & import videos | Yes | Yes |
| Basic editing (trim, cut, effects) | Yes | Yes |
| Templates (first 3) | Yes | All |
| AI Clipping | Yes | Yes |
| 720p export | Yes | Yes |
| 1080p export | No | Yes |
| Watermark on export | Yes | No |
| Background Removal | No | Yes |
| Advanced AI Captions | No | Yes |
| Priority Support | No | Yes |

---

## 22. Asset Structure

```
assets/
├── images/         # Full-size raster images used in screens
├── icons/          # SVG or PNG icons not covered by Iconsax
├── lottie/         # JSON Lottie animation files
└── watermark/
    └── clipai_watermark.png   # Applied bottom-right on free exports
```

All asset paths are declared in `lib/core/constants/app_assets.dart` to avoid hardcoded strings in widgets.

---

## 23. Error Handling

The app uses a typed exception system in `lib/core/errors/app_exceptions.dart`:

```dart
// All exceptions extend AppException
class NetworkException extends AppException { ... }
class AuthException extends AppException { ... }
class NotFoundException extends AppException { ... }
class ServerException extends AppException { ... }
class UnknownException extends AppException { ... }
```

Repository implementations catch raw exceptions (Supabase errors, platform errors) and wrap them in the appropriate `AppException`, then return as `Failure<T>`.

BLoC events call repository methods and handle both `Success` and `Failure` in a `result.when(...)` block to emit appropriate UI states.

Uncaught errors are forwarded to Firebase Crashlytics via:
1. `FlutterError.onError` in `main()`
2. `PlatformDispatcher.instance.onError` in `main()`
3. `CrashlyticsBlocObserver.onError()` for BLoC-level errors

---

## 24. Key Files Quick Reference

| File | Purpose |
|---|---|
| `lib/main.dart` | App bootstrap: Firebase, Supabase, Hive, DI, BLoC observer, FCM |
| `lib/app.dart` | Root MaterialApp.router with theme and router |
| `lib/core/constants/api_constants.dart` | All API keys and product IDs |
| `lib/core/constants/app_colors.dart` | Complete color palette |
| `lib/core/constants/app_strings.dart` | All UI text strings |
| `lib/core/di/injection.dart` | GetIt registration for all dependencies |
| `lib/core/routing/app_router.dart` | All routes, redirect logic, bottom nav shell |
| `lib/services/imgly_service.dart` | IMG.LY platform channel client (Dart) |
| `lib/services/subscription_service.dart` | RevenueCat wrapper + feature gates |
| `lib/services/analytics_service.dart` | Firebase Analytics events + Crashlytics |
| `lib/services/notification_service.dart` | FCM push notifications + local notifications |
| `android/.../MainActivity.kt` | Android IMG.LY MethodChannel handler |
| `ios/Runner/AppDelegate.swift` | iOS IMG.LY MethodChannel handler |
| `lib/data/datasources/supabase_datasource.dart` | All Supabase table operations |
| `lib/data/datasources/local_datasource.dart` | Hive offline cache |

---

## License

This project is proprietary. All rights reserved.
