# Graph Report - medico  (2026-08-22)

## Corpus Check
- 73 files · ~38,271 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 941 nodes · 1146 edges · 80 communities (36 shown, 44 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 21 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `5cf9d27c`
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
- aurora_tokens.dart
- _In_
- manifest.json
- queue_status_card.dart
- onboarding_v6.jsx
- onboarding_gender_control.dart
- MainActivity.kt
- One Screen Per File Rule
- FlView
- Dart analyzer configuration
- onboarding_step_scaffold.dart
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
- onboarding_flow_screen.dart
- onboarding_completion_screen.dart
- onboarding_year_picker_sheet.dart
- onboarding_step3_notifications.dart
- onboarding_city_picker_sheet.dart
- onboarding_milestone_stepper.dart
- aurora_buttons.dart
- onboarding_step_header.dart
- queue_status_card_preview.dart
- _OnboardingCompletionScreenState
- _CheckmarkPainter
- OtpPurpose
- UserProfile?

## God Nodes (most connected - your core abstractions)
1. `usePress()` - 7 edges
2. `AppDelegate` - 5 edges
3. `signup_verified Gate` - 5 edges
4. `Password Reset Web Page` - 5 edges
5. `Recovery Token Verification` - 5 edges
6. `OnboardingData` - 4 edges
7. `_OnboardingCompletionScreenState` - 4 edges
8. `_OnboardingStep3NotificationsState` - 4 edges
9. `OtpVerificationScreen` - 4 edges
10. `_OtpVerificationScreenState` - 4 edges

## Surprising Connections (you probably didn't know these)
- `ERROR_CODE_MESSAGES` --semantically_similar_to--> `_codeMessages`  [INFERRED] [semantically similar]
  web/reset-password/index.html → lib/utils/auth_error_mapper.dart
- `mapUpdatePasswordError` --semantically_similar_to--> `mapAuthError`  [INFERRED] [semantically similar]
  web/reset-password/index.html → lib/utils/auth_error_mapper.dart
- `signup_verified Gate` --conceptually_related_to--> `_resendConfirmation`  [INFERRED]
  CLAUDE.md → lib/screens/sign_in_page.dart
- `signup_verified Gate` --references--> `markSignupVerified`  [INFERRED]
  CLAUDE.md → lib/services/profile_service.dart
- `signup_verified Gate` --references--> `signupVerified`  [INFERRED]
  CLAUDE.md → lib/models/user_profile.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Recovery-Confirmed Account Re-Verification Flow** — web_reset_password_index_recovery_verify, claude_signup_verified_gate, lib_models_user_profile_signupverified, lib_screens_sign_in_page_resendconfirmation, lib_screens_otp_verification_screen_otppurpose, lib_services_profile_service_marksignupverified [INFERRED 0.90]
- **Reset Page Screen State Machine** — web_reset_password_index_page, web_reset_password_index_screens, web_reset_password_index_showscreen, web_reset_password_index_showfatalerror [EXTRACTED 1.00]
- **Arabic Auth Error Copy (Dart + JS, no shared code)** — web_reset_password_index_mapupdatepassworderror, web_reset_password_index_error_code_messages, lib_utils_auth_error_mapper_mapautherror, lib_utils_auth_error_mapper_codemessages [INFERRED 0.85]

## Communities (80 total, 44 thin omitted)

### Community 0 - "sign_in_page.dart"
Cohesion: 0.03
Nodes (63): _banner, build, _buildBrand, _buildCard, _buildDivider, _buildFieldError, _buildForm, _buildGoogleButton (+55 more)

### Community 2 - "sign_up_screen.dart"
Cohesion: 0.04
Nodes (53): double get, _agreedToPrivacy, _banner, build, _buildBrand, _buildCard, _buildDivider, _buildFieldGroup (+45 more)

### Community 3 - "otp_verification_screen.dart"
Cohesion: 0.04
Nodes (45): _bannerRetry, build, _buildBody, _buildBrand, _buildCard, _buildForm, _buildPasswordUnchangedNote, _buildPinInput (+37 more)

### Community 4 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (33): Any, app_links, Cocoa, firebase_core, firebase_crashlytics, firebase_messaging, Flutter, FlutterAppDelegate (+25 more)

### Community 5 - "auth_error_mapper.dart"
Cohesion: 0.06
Nodes (33): accountAlreadyExistsMessage, any, AuthErrorInfo, code, _codeMessages, doctorTabGoogleCreatedPatientMessage, doctorTabNotADoctorAccountMessage, emailNotConfirmedMessage (+25 more)

### Community 6 - "forgot_password_sheet.dart"
Cohesion: 0.05
Nodes (39): auth_error_banner.dart, AuthErrorInfo?, Aurora Sheet Design System, Password Policy: 8 Chars, No Composition Rule, signup_verified Gate, signupVerified, _GradientBackdrop, OtpPurpose (+31 more)

### Community 7 - "package:flutter/material.dart"
Cohesion: 0.05
Nodes (36): Checkbox, build, main, _PreviewApp, BookingsTab, build, BrowseTab, build (+28 more)

### Community 8 - "main.dart"
Cohesion: 0.05
Nodes (35): dart:io, android, DefaultFirebaseOptions, ios, macos, web, windows, build (+27 more)

### Community 10 - "auth_error_banner.dart"
Cohesion: 0.09
Nodes (22): AuthErrorBanner, _AuthErrorBannerState, AuthErrorSeverity, autoDismiss, _autoDismissDelay, _autoDismissTimer, build, createState (+14 more)

### Community 11 - "user_profile.dart"
Cohesion: 0.08
Nodes (26): bool get, int?, arabicLabel, birthYear, city, copyWith, fromText, hasCity (+18 more)

### Community 12 - "StatelessWidget"
Cohesion: 0.14
Nodes (14): _SoftCircle, _GradientBackdrop, _SoftCircle, _GradientBackdrop, _SoftCircle, AuroraPrimaryButton, AuroraSecondaryButton, AuroraSectionTitle (+6 more)

### Community 13 - "aurora_tokens.dart"
Cohesion: 0.04
Nodes (52): aurora, AuroraColors, AuroraFontSize, AuroraGradients, AuroraMotion, AuroraRadius, AuroraShadows, AuroraSpacing (+44 more)

### Community 15 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 16 - "queue_status_card.dart"
Cohesion: 0.05
Nodes (38): avgConsultMinutes, _blobControllers, _blobDurations, blurred, build, card, connectionStatus, controller (+30 more)

### Community 17 - "onboarding_v6.jsx"
Cohesion: 0.07
Nodes (20): bodyFont, C, CURRENT_YEAR, displayFont, E, F, GOVERNORATES, InlineSkipButton() (+12 more)

### Community 18 - "onboarding_gender_control.dart"
Cohesion: 0.05
Nodes (46): Google G Logo Mark, bookings_tab.dart, browse_tab.dart, Auth Fallback Chain, home_tab.dart, _PreviewApp, _PreviewAppState, Gender (+38 more)

### Community 26 - "onboarding_step_scaffold.dart"
Cohesion: 0.05
Nodes (45): aurora_buttons.dart, IconData, OnboardingData, build, data, OnboardingStep1Basics, onChanged, onContinue (+37 more)

### Community 62 - "arabic_formatting.dart"
Cohesion: 0.12
Nodes (15): buffer, _countedPhrase, digits, _easternArabicDigits, formatArabicClock12, hour12, hour24, minute (+7 more)

### Community 63 - "splash_screen.dart"
Cohesion: 0.18
Nodes (10): dart:async, home_screen.dart, _bootstrap, build, _destinationForSession, SplashScreen, onboarding_flow_screen.dart, ../services/profile_service.dart (+2 more)

### Community 64 - "wait_estimate.dart"
Cohesion: 0.20
Nodes (9): arabic_formatting.dart, add, estimatedTurnTime, high, low, _roundToNearest5, total, totalWaitMinutes (+1 more)

### Community 65 - "SignInPage"
Cohesion: 0.40
Nodes (4): SignInPage, _SignInPageState, SignInScreen, sign_in_page.dart

### Community 66 - "_resendConfirmation"
Cohesion: 0.50
Nodes (4): initState, _resendConfirmation, _handleSubmit, MaterialPageRoute

### Community 67 - "onboarding_flow_screen.dart"
Cohesion: 0.08
Nodes (25): build, _completionStep, createState, _data, dispose, _enableNotifications, _finish, _goTo (+17 more)

### Community 68 - "onboarding_completion_screen.dart"
Cohesion: 0.08
Nodes (23): Color, dart:ui, _badgeScale, _Blob, _blobBlue, build, _buttonFade, _checkDraw (+15 more)

### Community 69 - "onboarding_year_picker_sheet.dart"
Cohesion: 0.10
Nodes (21): FixedExtentScrollController, build, _controller, createState, dispose, _firstYear, initial, initState (+13 more)

### Community 70 - "onboarding_step3_notifications.dart"
Cohesion: 0.10
Nodes (20): Animation, AnimationController, class, build, _Chip, _ChipRow, _chips, createState (+12 more)

### Community 71 - "onboarding_city_picker_sheet.dart"
Cohesion: 0.12
Nodes (17): build, _CityPickerSheet, _CityPickerSheetState, _CityRow, createState, current, dispose, kGovernorates (+9 more)

### Community 72 - "onboarding_milestone_stepper.dart"
Cohesion: 0.12
Nodes (16): build, _column, _half, height, index, isActive, isDone, _labelGap (+8 more)

### Community 73 - "aurora_buttons.dart"
Cohesion: 0.12
Nodes (15): AuroraIconButton, build, child, createState, _enabled, hint, icon, label (+7 more)

### Community 74 - "onboarding_step_header.dart"
Cohesion: 0.17
Nodes (11): build, _height, _markGap, _markHeight, _MedicoMark, OnboardingStepHeader, step, _topPadding (+3 more)

### Community 75 - "queue_status_card_preview.dart"
Cohesion: 0.18
Nodes (10): DateTime, build, createState, initState, main, _recordedAt, _setStatus, _status (+2 more)

### Community 76 - "_OnboardingCompletionScreenState"
Cohesion: 0.40
Nodes (5): OnboardingCompletionScreen, _OnboardingCompletionScreenState, OnboardingStep3Notifications, _OnboardingStep3NotificationsState, SingleTickerProviderStateMixin

## Ambiguous Edges - Review These
- `One Screen Per File Rule` → `Graphify Skill Trigger`  [AMBIGUOUS]
  .claude/CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **589 isolated node(s):** `main`, `build`, `arabicLabel`, `text`, `birthYear` (+584 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **44 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `One Screen Per File Rule` and `Graphify Skill Trigger`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `_OtpVerificationScreenState` connect `onboarding_gender_control.dart` to `otp_verification_screen.dart`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Why does `SignInPage` connect `SignInPage` to `sign_in_page.dart`, `onboarding_gender_control.dart`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **What connects `main`, `build`, `arabicLabel` to the rest of the system?**
  _589 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `sign_in_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03125 - nodes in this community are weakly interconnected._
- **Should `sign_up_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.037037037037037035 - nodes in this community are weakly interconnected._
- **Should `otp_verification_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.043478260869565216 - nodes in this community are weakly interconnected._