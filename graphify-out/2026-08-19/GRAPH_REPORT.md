# Graph Report - .  (2026-08-14)

## Corpus Check
- 31 files · ~24,294 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 583 nodes · 735 edges · 33 communities (23 shown, 10 thin omitted)
- Extraction: 94% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 40 edges (avg confidence: 0.84)
- Token cost: 12,400 input · 2,600 output

## Community Hubs (Navigation)
- Sign-In Screen
- Windows Runner Host
- Sign-Up Screen
- OTP Verification Screen
- Apple Platform Bootstrap
- Auth Error Mapping
- Forgot Password Sheet
- Widget Test Suite
- App Bootstrap and Firebase Config
- Linux Runner Host
- Auth Error Banner
- Profile and Signup Verification
- Aurora Design and Reset Page
- Auth Entry and Dependencies
- Windows Console Utilities
- Web App Manifest
- Splash Routing and Session
- CMake Build Targets
- Sign-In Resend Actions
- Android Activity Entry
- Project Instruction Rules
- Sign-Up Widget Pair
- Dart Analyzer Config
- AuthErrorInfo Type
- DevTools Config
- iOS LaunchImage Assets
- Nullable String Type
- Project README
- Flutter Web Entrypoint

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 22 edges
2. `MessageHandler` - 12 edges
3. `FlutterWindow` - 10 edges
4. `Create` - 10 edges
5. `WndProc` - 10 edges
6. `MessageHandler` - 9 edges
7. `_MyApplication` - 7 edges
8. `OnCreate` - 7 edges
9. `WindowClassRegistrar` - 7 edges
10. `Destroy` - 7 edges

## Surprising Connections (you probably didn't know these)
- `ERROR_CODE_MESSAGES` --semantically_similar_to--> `_codeMessages`  [INFERRED] [semantically similar]
  web/reset-password/index.html → lib/utils/auth_error_mapper.dart
- `mapUpdatePasswordError` --semantically_similar_to--> `mapAuthError`  [INFERRED] [semantically similar]
  web/reset-password/index.html → lib/utils/auth_error_mapper.dart
- `signup_verified Gate` --conceptually_related_to--> `_resendConfirmation`  [INFERRED]
  CLAUDE.md → lib/screens/sign_in_page.dart
- `signup_verified Gate` --references--> `markSignupVerified`  [INFERRED]
  CLAUDE.md → lib/services/profile_service.dart
- `Linux top-level CMake build config` --semantically_similar_to--> `Windows top-level CMake build config`  [INFERRED] [semantically similar]
  linux/CMakeLists.txt → windows/CMakeLists.txt

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Recovery-Confirmed Account Re-Verification Flow** — web_reset_password_index_recovery_verify, claude_signup_verified_gate, lib_models_user_profile_signupverified, lib_screens_sign_in_page_resendconfirmation, lib_screens_otp_verification_screen_otppurpose, lib_services_profile_service_marksignupverified [INFERRED 0.90]
- **Reset Page Screen State Machine** — web_reset_password_index_page, web_reset_password_index_screens, web_reset_password_index_showscreen, web_reset_password_index_showfatalerror [EXTRACTED 1.00]
- **Arabic Auth Error Copy (Dart + JS, no shared code)** — web_reset_password_index_mapupdatepassworderror, web_reset_password_index_error_code_messages, lib_utils_auth_error_mapper_mapautherror, lib_utils_auth_error_mapper_codemessages [INFERRED 0.85]
- **Cross-platform CMake build configs (Linux & Windows)** — linux_cmakelists_linux_build_config, linux_flutter_cmakelists_flutter_library_target, linux_runner_cmakelists_runner_executable_target, windows_cmakelists_windows_build_config, windows_flutter_cmakelists_flutter_library_target, windows_runner_cmakelists_runner_executable_target [INFERRED 0.80]

## Communities (33 total, 10 thin omitted)

### Community 0 - "Sign-In Screen"
Cohesion: 0.03
Nodes (68): _banner, _border, build, _buildBrand, _buildCard, _buildDivider, _buildFieldError, _buildForm (+60 more)

### Community 1 - "Windows Runner Host"
Cohesion: 0.06
Nodes (53): PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject, HWND (+45 more)

### Community 2 - "Sign-Up Screen"
Cohesion: 0.03
Nodes (60): double get, _agreedToPrivacy, _banner, _border, build, _buildBrand, _buildCard, _buildDivider (+52 more)

### Community 3 - "OTP Verification Screen"
Cohesion: 0.04
Nodes (53): DateTime, _bannerRetry, _border, build, _buildBody, _buildBrand, _buildCard, _buildForm (+45 more)

### Community 4 - "Apple Platform Bootstrap"
Cohesion: 0.05
Nodes (33): Any, app_links, Cocoa, firebase_core, firebase_crashlytics, firebase_messaging, Flutter, FlutterAppDelegate (+25 more)

### Community 5 - "Auth Error Mapping"
Cohesion: 0.06
Nodes (31): accountAlreadyExistsMessage, any, AuthErrorInfo, code, _codeMessages, emailNotConfirmedMessage, error, genericAuthErrorMessage (+23 more)

### Community 6 - "Forgot Password Sheet"
Cohesion: 0.07
Nodes (29): auth_error_banner.dart, _banner, _border, build, _cooldown, _cooldownSeconds, _cooldownTimer, createState (+21 more)

### Community 7 - "Widget Test Suite"
Cohesion: 0.08
Nodes (25): Checkbox, build, HomeScreen, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:medico/main.dart, package:medico/screens/sign_in_page.dart, package:medico/screens/sign_up_screen.dart (+17 more)

### Community 8 - "App Bootstrap and Firebase Config"
Cohesion: 0.07
Nodes (25): android, DefaultFirebaseOptions, ios, macos, web, windows, build, buildOverscrollIndicator (+17 more)

### Community 9 - "Linux Runner Host"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 10 - "Auth Error Banner"
Cohesion: 0.08
Nodes (25): _amber, AuthErrorBanner, _AuthErrorBannerState, AuthErrorSeverity, _autoDismissDelay, _autoDismissTimer, build, createState (+17 more)

### Community 11 - "Profile and Signup Verification"
Cohesion: 0.10
Nodes (21): bool get, signup_verified Gate, doctor, fromMap, fromText, fullName, id, isDoctor (+13 more)

### Community 12 - "Aurora Design and Reset Page"
Cohesion: 0.11
Nodes (18): Aurora Sheet Design System, Password Policy: 8 Chars, No Composition Rule, MedicoApp, _GradientBackdrop, _SoftCircle, _GradientBackdrop, _SoftCircle, _GradientBackdrop (+10 more)

### Community 13 - "Auth Entry and Dependencies"
Cohesion: 0.15
Nodes (15): Google G Logo Mark, Auth Fallback Chain, OtpVerificationScreen, _OtpVerificationScreenState, SignInPage, _SignInPageState, SignInScreen, flutter_svg Dependency (+7 more)

### Community 14 - "Windows Console Utilities"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 15 - "Web App Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 16 - "Splash Routing and Session"
Cohesion: 0.20
Nodes (9): dart:async, dart:io, home_screen.dart, _bootstrap, build, _destinationForSession, ../services/profile_service.dart, sign_in_screen.dart (+1 more)

### Community 17 - "CMake Build Targets"
Cohesion: 0.60
Nodes (6): Linux top-level CMake build config, Linux flutter library CMake target, Linux runner executable CMake target, Windows top-level CMake build config, Windows flutter library CMake target, Windows runner executable CMake target

### Community 18 - "Sign-In Resend Actions"
Cohesion: 0.50
Nodes (4): initState, _resendConfirmation, _handleSubmit, MaterialPageRoute

## Ambiguous Edges - Review These
- `One Screen Per File Rule` → `Graphify Skill Trigger`  [AMBIGUOUS]
  .claude/CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **322 isolated node(s):** `DefaultFirebaseOptions`, `web`, `android`, `ios`, `macos` (+317 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `One Screen Per File Rule` and `Graphify Skill Trigger`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `FlutterWindow` connect `Windows Runner Host` to `Apple Platform Bootstrap`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Why does `AuthErrorInfo` connect `Auth Error Mapping` to `Sign-In Screen`, `Sign-Up Screen`, `Forgot Password Sheet`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `MessageHandler` (e.g. with `Destroy` and `GetClientArea`) actually correct?**
  _`MessageHandler` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `Create` (e.g. with `Destroy` and `UpdateTheme`) actually correct?**
  _`Create` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `DefaultFirebaseOptions`, `web`, `android` to the rest of the system?**
  _322 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Sign-In Screen` be split into smaller, more focused modules?**
  _Cohesion score 0.028985507246376812 - nodes in this community are weakly interconnected._