# Graph Report - medico  (2026-08-19)

## Corpus Check
- 45 files · ~21,398 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 516 nodes · 568 edges · 60 communities (18 shown, 42 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 21 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `6d8ffc35`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- sign_in_page.dart
- PluginRegistry
- sign_up_screen.dart
- otp_verification_screen.dart
- GeneratedPluginRegistrant.swift
- auth_error_mapper.dart
- forgot_password_sheet.dart
- package:flutter/material.dart
- main.dart
- FlPluginRegistry
- auth_error_banner.dart
- user_profile.dart
- StatelessWidget
- signup_verified Gate
- _In_
- manifest.json
- AppDelegate
- MainActivity.kt
- One Screen Per File Rule
- FlView
- Dart analyzer configuration
- AuthErrorInfo?
- Flutter DevTools configuration
- iOS LaunchImage asset instructions
- String?
- medico project README
- Flutter web index.html entrypoint
- GApplication
- gboolean
- gchar
- GObject
- GtkApplication
- _In_opt_
- MyApplicationClass
- Point
- RECT
- Size
- unique_ptr
- vector
- DartProject
- HWND
- LPARAM
- LRESULT
- UINT
- WPARAM
- DartProject
- string
- wchar_t
- HWND
- LPARAM
- LRESULT
- UINT
- wchar_t
- WPARAM
- HWND
- wstring

## God Nodes (most connected - your core abstractions)
1. `AppDelegate` - 5 edges
2. `signup_verified Gate` - 5 edges
3. `Password Reset Web Page` - 5 edges
4. `Recovery Token Verification` - 5 edges
5. `SignInPage` - 4 edges
6. `AuthErrorInfo` - 4 edges
7. `FlutterMacOS` - 4 edges
8. `AppDelegate` - 4 edges
9. `OtpVerificationScreen` - 4 edges
10. `_OtpVerificationScreenState` - 4 edges

## Surprising Connections (you probably didn't know these)
- `ERROR_CODE_MESSAGES` --semantically_similar_to--> `_codeMessages`  [INFERRED] [semantically similar]
  web/reset-password/index.html → lib/utils/auth_error_mapper.dart
- `mapUpdatePasswordError` --semantically_similar_to--> `mapAuthError`  [INFERRED] [semantically similar]
  web/reset-password/index.html → lib/utils/auth_error_mapper.dart
- `Recovery Token Verification` --conceptually_related_to--> `OtpPurpose`  [INFERRED]
  web/reset-password/index.html → lib/screens/otp_verification_screen.dart
- `signup_verified Gate` --references--> `markSignupVerified`  [INFERRED]
  CLAUDE.md → lib/services/profile_service.dart
- `signup_verified Gate` --conceptually_related_to--> `_resendConfirmation`  [INFERRED]
  CLAUDE.md → lib/screens/sign_in_page.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Recovery-Confirmed Account Re-Verification Flow** — web_reset_password_index_recovery_verify, claude_signup_verified_gate, lib_models_user_profile_signupverified, lib_screens_sign_in_page_resendconfirmation, lib_screens_otp_verification_screen_otppurpose, lib_services_profile_service_marksignupverified [INFERRED 0.90]
- **Reset Page Screen State Machine** — web_reset_password_index_page, web_reset_password_index_screens, web_reset_password_index_showscreen, web_reset_password_index_showfatalerror [EXTRACTED 1.00]
- **Arabic Auth Error Copy (Dart + JS, no shared code)** — web_reset_password_index_mapupdatepassworderror, web_reset_password_index_error_code_messages, lib_utils_auth_error_mapper_mapautherror, lib_utils_auth_error_mapper_codemessages [INFERRED 0.85]

## Communities (60 total, 42 thin omitted)

### Community 0 - "sign_in_page.dart"
Cohesion: 0.03
Nodes (72): _banner, _border, build, _buildBrand, _buildCard, _buildDivider, _buildFieldError, _buildForm (+64 more)

### Community 2 - "sign_up_screen.dart"
Cohesion: 0.03
Nodes (60): double get, _agreedToPrivacy, _banner, _border, build, _buildBrand, _buildCard, _buildDivider (+52 more)

### Community 3 - "otp_verification_screen.dart"
Cohesion: 0.04
Nodes (53): DateTime, _bannerRetry, _border, build, _buildBody, _buildBrand, _buildCard, _buildForm (+45 more)

### Community 4 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.07
Nodes (23): app_links, Cocoa, firebase_core, firebase_crashlytics, firebase_messaging, Flutter, FlutterMacOS, FlutterPluginRegistry (+15 more)

### Community 5 - "auth_error_mapper.dart"
Cohesion: 0.06
Nodes (33): accountAlreadyExistsMessage, any, AuthErrorInfo, code, _codeMessages, doctorTabGoogleCreatedPatientMessage, doctorTabNotADoctorAccountMessage, emailNotConfirmedMessage (+25 more)

### Community 6 - "forgot_password_sheet.dart"
Cohesion: 0.05
Nodes (40): auth_error_banner.dart, dart:async, dart:io, home_screen.dart, _bootstrap, build, _destinationForSession, fetchCurrentProfile (+32 more)

### Community 7 - "package:flutter/material.dart"
Cohesion: 0.08
Nodes (25): Checkbox, build, HomeScreen, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:medico/main.dart, package:medico/screens/sign_in_page.dart, package:medico/screens/sign_up_screen.dart (+17 more)

### Community 8 - "main.dart"
Cohesion: 0.09
Nodes (21): android, DefaultFirebaseOptions, ios, macos, web, windows, build, buildOverscrollIndicator (+13 more)

### Community 10 - "auth_error_banner.dart"
Cohesion: 0.08
Nodes (24): _amber, AuthErrorSeverity, autoDismiss, _autoDismissDelay, _autoDismissTimer, build, createState, didUpdateWidget (+16 more)

### Community 11 - "user_profile.dart"
Cohesion: 0.12
Nodes (15): bool get, doctor, fromMap, fromText, fullName, id, isDoctor, phone (+7 more)

### Community 12 - "StatelessWidget"
Cohesion: 0.11
Nodes (18): Aurora Sheet Design System, Password Policy: 8 Chars, No Composition Rule, MedicoApp, _GradientBackdrop, _SoftCircle, _GradientBackdrop, _SoftCircle, _GradientBackdrop (+10 more)

### Community 13 - "signup_verified Gate"
Cohesion: 0.08
Nodes (31): Google G Logo Mark, Auth Fallback Chain, signup_verified Gate, signupVerified, OtpPurpose, OtpVerificationScreen, _OtpVerificationScreenState, initState (+23 more)

### Community 15 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 17 - "AppDelegate"
Cohesion: 0.16
Nodes (10): Any, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, AppDelegate, Bool, AppDelegate, Bool (+2 more)

## Ambiguous Edges - Review These
- `One Screen Per File Rule` → `Graphify Skill Trigger`  [AMBIGUOUS]
  .claude/CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **318 isolated node(s):** `_Role`, `initialErrorMessage`, `initialUnconfirmedEmail`, `_teal`, `_ink` (+313 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **42 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `One Screen Per File Rule` and `Graphify Skill Trigger`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `AuthErrorInfo` connect `auth_error_mapper.dart` to `sign_in_page.dart`, `sign_up_screen.dart`, `forgot_password_sheet.dart`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Why does `Password Reset Web Page` connect `StatelessWidget` to `signup_verified Gate`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Why does `_OtpVerificationScreenState` connect `signup_verified Gate` to `otp_verification_screen.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `_Role`, `initialErrorMessage`, `initialUnconfirmedEmail` to the rest of the system?**
  _318 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `sign_in_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0273972602739726 - nodes in this community are weakly interconnected._
- **Should `sign_up_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03278688524590164 - nodes in this community are weakly interconnected._