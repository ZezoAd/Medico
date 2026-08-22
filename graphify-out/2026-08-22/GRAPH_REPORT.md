# Graph Report - medico  (2026-08-22)

## Corpus Check
- 54 files · ~28,608 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 661 nodes · 740 edges · 67 communities (25 shown, 42 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 21 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `7c7678c3`
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
- package:supabase_flutter/supabase_flutter.dart
- _In_
- manifest.json
- queue_status_card.dart
- onboarding_v6.jsx
- queue_status_card_preview.dart
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
- arabic_formatting.dart
- splash_screen.dart
- wait_estimate.dart
- SignInPage
- _resendConfirmation

## God Nodes (most connected - your core abstractions)
1. `usePress()` - 7 edges
2. `AppDelegate` - 5 edges
3. `signup_verified Gate` - 5 edges
4. `Password Reset Web Page` - 5 edges
5. `Recovery Token Verification` - 5 edges
6. `_QueueStatusCardState` - 4 edges
7. `SignInPage` - 4 edges
8. `AuthErrorInfo` - 4 edges
9. `FlutterMacOS` - 4 edges
10. `AppDelegate` - 4 edges

## Surprising Connections (you probably didn't know these)
- `ERROR_CODE_MESSAGES` --semantically_similar_to--> `_codeMessages`  [INFERRED] [semantically similar]
  web/reset-password/index.html → lib/utils/auth_error_mapper.dart
- `mapUpdatePasswordError` --semantically_similar_to--> `mapAuthError`  [INFERRED] [semantically similar]
  web/reset-password/index.html → lib/utils/auth_error_mapper.dart
- `signup_verified Gate` --conceptually_related_to--> `_resendConfirmation`  [INFERRED]
  CLAUDE.md → lib/screens/sign_in_page.dart
- `Recovery Token Verification` --conceptually_related_to--> `OtpPurpose`  [INFERRED]
  web/reset-password/index.html → lib/screens/otp_verification_screen.dart
- `signup_verified Gate` --references--> `markSignupVerified`  [INFERRED]
  CLAUDE.md → lib/services/profile_service.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Recovery-Confirmed Account Re-Verification Flow** — web_reset_password_index_recovery_verify, claude_signup_verified_gate, lib_models_user_profile_signupverified, lib_screens_sign_in_page_resendconfirmation, lib_screens_otp_verification_screen_otppurpose, lib_services_profile_service_marksignupverified [INFERRED 0.90]
- **Reset Page Screen State Machine** — web_reset_password_index_page, web_reset_password_index_screens, web_reset_password_index_showscreen, web_reset_password_index_showfatalerror [EXTRACTED 1.00]
- **Arabic Auth Error Copy (Dart + JS, no shared code)** — web_reset_password_index_mapupdatepassworderror, web_reset_password_index_error_code_messages, lib_utils_auth_error_mapper_mapautherror, lib_utils_auth_error_mapper_codemessages [INFERRED 0.85]

## Communities (67 total, 42 thin omitted)

### Community 0 - "sign_in_page.dart"
Cohesion: 0.03
Nodes (72): _banner, _border, build, _buildBrand, _buildCard, _buildDivider, _buildFieldError, _buildForm (+64 more)

### Community 2 - "sign_up_screen.dart"
Cohesion: 0.03
Nodes (60): double get, _agreedToPrivacy, _banner, _border, build, _buildBrand, _buildCard, _buildDivider (+52 more)

### Community 3 - "otp_verification_screen.dart"
Cohesion: 0.04
Nodes (52): _bannerRetry, _border, build, _buildBody, _buildBrand, _buildCard, _buildForm, _buildPasswordUnchangedNote (+44 more)

### Community 4 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (33): Any, app_links, Cocoa, firebase_core, firebase_crashlytics, firebase_messaging, Flutter, FlutterAppDelegate (+25 more)

### Community 5 - "auth_error_mapper.dart"
Cohesion: 0.06
Nodes (33): accountAlreadyExistsMessage, any, AuthErrorInfo, code, _codeMessages, doctorTabGoogleCreatedPatientMessage, doctorTabNotADoctorAccountMessage, emailNotConfirmedMessage (+25 more)

### Community 6 - "forgot_password_sheet.dart"
Cohesion: 0.05
Nodes (37): auth_error_banner.dart, Aurora Sheet Design System, Password Policy: 8 Chars, No Composition Rule, _GradientBackdrop, _banner, _border, build, _cooldown (+29 more)

### Community 7 - "package:flutter/material.dart"
Cohesion: 0.06
Nodes (31): Checkbox, BookingsTab, build, BrowseTab, build, build, HomeTab, build (+23 more)

### Community 8 - "main.dart"
Cohesion: 0.08
Nodes (22): android, DefaultFirebaseOptions, ios, macos, web, windows, build, buildOverscrollIndicator (+14 more)

### Community 10 - "auth_error_banner.dart"
Cohesion: 0.08
Nodes (25): _amber, AuthErrorBanner, _AuthErrorBannerState, AuthErrorSeverity, autoDismiss, _autoDismissDelay, _autoDismissTimer, build (+17 more)

### Community 11 - "user_profile.dart"
Cohesion: 0.12
Nodes (15): bool get, doctor, fromMap, fromText, fullName, id, isDoctor, phone (+7 more)

### Community 12 - "StatelessWidget"
Cohesion: 0.18
Nodes (11): _SoftCircle, _GradientBackdrop, _SoftCircle, _GradientBackdrop, _SoftCircle, _CardContent, _ConnectionBadge, _DoctorAvatar (+3 more)

### Community 13 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.12
Nodes (19): Google G Logo Mark, Auth Fallback Chain, signup_verified Gate, signupVerified, OtpPurpose, OtpVerificationScreen, _OtpVerificationScreenState, fetchCurrentProfile (+11 more)

### Community 15 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 16 - "queue_status_card.dart"
Cohesion: 0.05
Nodes (42): AnimationController, dart:ui, avgConsultMinutes, _blobControllers, _blobDurations, blurred, build, card (+34 more)

### Community 17 - "onboarding_v6.jsx"
Cohesion: 0.07
Nodes (20): bodyFont, C, CURRENT_YEAR, displayFont, E, F, GOVERNORATES, InlineSkipButton() (+12 more)

### Community 18 - "queue_status_card_preview.dart"
Cohesion: 0.07
Nodes (32): bookings_tab.dart, browse_tab.dart, DateTime, home_tab.dart, build, createState, initState, main (+24 more)

### Community 62 - "arabic_formatting.dart"
Cohesion: 0.12
Nodes (15): buffer, _countedPhrase, digits, _easternArabicDigits, formatArabicClock12, hour12, hour24, minute (+7 more)

### Community 63 - "splash_screen.dart"
Cohesion: 0.18
Nodes (10): dart:async, dart:io, home_screen.dart, _bootstrap, build, _destinationForSession, SplashScreen, ../services/profile_service.dart (+2 more)

### Community 64 - "wait_estimate.dart"
Cohesion: 0.20
Nodes (9): arabic_formatting.dart, add, estimatedTurnTime, high, low, _roundToNearest5, total, totalWaitMinutes (+1 more)

### Community 65 - "SignInPage"
Cohesion: 0.40
Nodes (4): SignInPage, _SignInPageState, SignInScreen, sign_in_page.dart

### Community 66 - "_resendConfirmation"
Cohesion: 0.50
Nodes (4): initState, _resendConfirmation, _handleSubmit, MaterialPageRoute

## Ambiguous Edges - Review These
- `One Screen Per File Rule` → `Graphify Skill Trigger`  [AMBIGUOUS]
  .claude/CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **402 isolated node(s):** `C`, `S`, `R`, `F`, `M` (+397 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **42 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `One Screen Per File Rule` and `Graphify Skill Trigger`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `AuthErrorInfo` connect `auth_error_mapper.dart` to `sign_in_page.dart`, `sign_up_screen.dart`, `forgot_password_sheet.dart`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `Password Reset Web Page` connect `forgot_password_sheet.dart` to `package:supabase_flutter/supabase_flutter.dart`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Why does `_OtpVerificationScreenState` connect `package:supabase_flutter/supabase_flutter.dart` to `queue_status_card_preview.dart`, `otp_verification_screen.dart`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **What connects `C`, `S`, `R` to the rest of the system?**
  _402 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `sign_in_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0273972602739726 - nodes in this community are weakly interconnected._
- **Should `sign_up_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03278688524590164 - nodes in this community are weakly interconnected._