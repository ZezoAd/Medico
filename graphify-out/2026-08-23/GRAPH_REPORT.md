# Graph Report - medico  (2026-08-23)

## Corpus Check
- 78 files · ~43,836 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 990 nodes · 1259 edges · 54 communities (45 shown, 9 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 20 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `843f64c5`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- sign_in_page.dart
- ConnectivityArchitecture.jsx
- sign_up_screen.dart
- otp_verification_screen.dart
- GeneratedPluginRegistrant.swift
- auth_error_mapper.dart
- forgot_password_sheet.dart
- sign_up_screen_test.dart
- main.dart
- _codeMessages
- auth_error_banner.dart
- user_profile.dart
- StatelessWidget
- aurora_tokens.dart
- SignUpScreen
- manifest.json
- queue_status_card.dart
- onboarding_v6.jsx
- State
- MainActivity.kt
- One Screen Per File Rule
- Dart analyzer configuration
- onboarding_step1_basics.dart
- Flutter DevTools configuration
- iOS LaunchImage asset instructions
- medico project README
- Flutter web index.html entrypoint
- arabic_formatting.dart
- auth_gate.dart
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
- _OnboardingCompletionScreenState
- _CheckmarkPainter
- auth_gate.dart
- onboarding_sync_service.dart
- package:flutter/material.dart
- package:supabase_flutter/supabase_flutter.dart
- _QueueStatusCardState
- notification_service.dart
- onboarding_preview.dart
- firebase_options.dart

## God Nodes (most connected - your core abstractions)
1. `usePress()` - 7 edges
2. `AppDelegate` - 5 edges
3. `OnboardingData` - 5 edges
4. `signup_verified Gate` - 5 edges
5. `Password Reset Web Page` - 5 edges
6. `Recovery Token Verification` - 5 edges
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

## Communities (54 total, 9 thin omitted)

### Community 0 - "sign_in_page.dart"
Cohesion: 0.03
Nodes (61): _banner, build, _buildBrand, _buildCard, _buildDivider, _buildFieldError, _buildForm, _buildGoogleButton (+53 more)

### Community 1 - "ConnectivityArchitecture.jsx"
Cohesion: 0.29
Nodes (4): AR, AURORA, clock(), ConnectivityArchitecture()

### Community 2 - "sign_up_screen.dart"
Cohesion: 0.04
Nodes (53): double get, _agreedToPrivacy, _banner, build, _buildBrand, _buildCard, _buildDivider, _buildFieldGroup (+45 more)

### Community 3 - "otp_verification_screen.dart"
Cohesion: 0.04
Nodes (45): _bannerRetry, build, _buildBody, _buildBrand, _buildCard, _buildForm, _buildPasswordUnchangedNote, _buildPinInput (+37 more)

### Community 4 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (33): Any, app_links, Cocoa, connectivity_plus, firebase_core, firebase_crashlytics, firebase_messaging, Flutter (+25 more)

### Community 5 - "auth_error_mapper.dart"
Cohesion: 0.07
Nodes (28): accountAlreadyExistsMessage, any, code, doctorTabGoogleCreatedPatientMessage, doctorTabNotADoctorAccountMessage, emailNotConfirmedMessage, error, genericAuthErrorMessage (+20 more)

### Community 6 - "forgot_password_sheet.dart"
Cohesion: 0.05
Nodes (40): auth_error_banner.dart, Aurora Sheet Design System, Password Policy: 8 Chars, No Composition Rule, signup_verified Gate, signupVerified, _GradientBackdrop, OtpPurpose, markSignupVerified (+32 more)

### Community 7 - "sign_up_screen_test.dart"
Cohesion: 0.06
Nodes (29): Checkbox, package:flutter_test/flutter_test.dart, package:medico/main.dart, package:medico/models/onboarding_data.dart, package:medico/screens/sign_in_page.dart, package:medico/screens/sign_up_screen.dart, package:medico/services/onboarding_sync_service.dart, package:shared_preferences/shared_preferences.dart (+21 more)

### Community 8 - "main.dart"
Cohesion: 0.14
Nodes (13): build, buildOverscrollIndicator, initializeApp, load, main, MedicoApp, _NoStretchScrollBehavior, supabaseAnonKey (+5 more)

### Community 9 - "_codeMessages"
Cohesion: 0.50
Nodes (4): _codeMessages, mapAuthError, ERROR_CODE_MESSAGES, mapUpdatePasswordError

### Community 10 - "auth_error_banner.dart"
Cohesion: 0.09
Nodes (23): dart:async, AuthErrorBanner, _AuthErrorBannerState, AuthErrorSeverity, autoDismiss, _autoDismissDelay, _autoDismissTimer, build (+15 more)

### Community 11 - "user_profile.dart"
Cohesion: 0.07
Nodes (26): bool get, int?, arabicLabel, birthYear, city, copyWith, fromText, hasCity (+18 more)

### Community 12 - "StatelessWidget"
Cohesion: 0.12
Nodes (17): _SoftCircle, _GradientBackdrop, _SoftCircle, _GradientBackdrop, _SoftCircle, _BadgeShell, _CardContent, _ConnectionBadge (+9 more)

### Community 13 - "aurora_tokens.dart"
Cohesion: 0.04
Nodes (54): aurora, AuroraColors, AuroraFontSize, AuroraGradients, AuroraMotion, AuroraRadius, AuroraShadows, AuroraSpacing (+46 more)

### Community 15 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 16 - "queue_status_card.dart"
Cohesion: 0.05
Nodes (43): avgConsultMinutes, _blobControllers, _blobDurations, build, card, connectionStatus, controller, createState (+35 more)

### Community 17 - "onboarding_v6.jsx"
Cohesion: 0.07
Nodes (21): bodyFont, C, CURRENT_YEAR, displayFont, E, F, GOVERNORATES, InlineSkipButton() (+13 more)

### Community 18 - "State"
Cohesion: 0.06
Nodes (37): Google G Logo Mark, bookings_tab.dart, browse_tab.dart, Auth Fallback Chain, DateTime, home_tab.dart, build, createState (+29 more)

### Community 26 - "onboarding_step1_basics.dart"
Cohesion: 0.06
Nodes (34): Gender, build, _canSlide, createState, didUpdateWidget, initState, OnboardingGenderControl, _OnboardingGenderControlState (+26 more)

### Community 62 - "arabic_formatting.dart"
Cohesion: 0.11
Nodes (18): buffer, CountedParts, digits, _easternArabicDigits, formatArabicClock12, hour12, hour24, _joinParts (+10 more)

### Community 63 - "auth_gate.dart"
Cohesion: 0.50
Nodes (3): auth_gate.dart, build, SplashScreen

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
Cohesion: 0.06
Nodes (33): home_screen.dart, build, _completionStep, createState, _data, dispose, _enableNotifications, _finish (+25 more)

### Community 68 - "onboarding_completion_screen.dart"
Cohesion: 0.08
Nodes (23): Color, dart:ui, _badgeScale, _Blob, _blobBlue, build, _buttonFade, _checkDraw (+15 more)

### Community 69 - "onboarding_year_picker_sheet.dart"
Cohesion: 0.10
Nodes (21): FixedExtentScrollController, build, _controller, createState, dispose, _firstYear, initial, initState (+13 more)

### Community 70 - "onboarding_step3_notifications.dart"
Cohesion: 0.10
Nodes (19): Animation, AnimationController, class, build, _Chip, _ChipRow, _chips, createState (+11 more)

### Community 71 - "onboarding_city_picker_sheet.dart"
Cohesion: 0.12
Nodes (17): build, _CityPickerSheet, _CityPickerSheetState, _CityRow, createState, current, dispose, kGovernorates (+9 more)

### Community 72 - "onboarding_milestone_stepper.dart"
Cohesion: 0.12
Nodes (16): build, _column, _half, height, index, isActive, isDone, _labelGap (+8 more)

### Community 73 - "aurora_buttons.dart"
Cohesion: 0.05
Nodes (44): aurora_buttons.dart, IconData, build, children, footer, helperText, OnboardingStepFooter, OnboardingStepScaffold (+36 more)

### Community 74 - "onboarding_step_header.dart"
Cohesion: 0.17
Nodes (11): build, _height, _markGap, _markHeight, _MedicoMark, OnboardingStepHeader, step, _topPadding (+3 more)

### Community 76 - "_OnboardingCompletionScreenState"
Cohesion: 0.40
Nodes (5): OnboardingCompletionScreen, _OnboardingCompletionScreenState, OnboardingStep3Notifications, _OnboardingStep3NotificationsState, SingleTickerProviderStateMixin

### Community 80 - "auth_gate.dart"
Cohesion: 0.07
Nodes (29): AuthGate, _AuthGateState, build, _connectivitySub, createState, dispose, _drainPendingOnboarding, _failClosed (+21 more)

### Community 81 - "onboarding_sync_service.dart"
Cohesion: 0.11
Nodes (17): dart:convert, clearPending, clearProgress, data, hasPending, _key, loadProgress, _maxStep (+9 more)

### Community 83 - "package:flutter/material.dart"
Cohesion: 0.13
Nodes (14): BookingsTab, build, BrowseTab, build, build, HomeTab, build, SettingsTab (+6 more)

### Community 85 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.22
Nodes (7): OnboardingService, saveOnboarding, fetchCurrentProfile, ProfileService, ../models/onboarding_data.dart, ../models/user_profile.dart, package:supabase_flutter/supabase_flutter.dart

### Community 87 - "_QueueStatusCardState"
Cohesion: 0.67
Nodes (3): QueueStatusCard, _QueueStatusCardState, TickerProviderStateMixin

### Community 88 - "notification_service.dart"
Cohesion: 0.29
Nodes (6): dart:io, NotificationService, registerDeviceToken, requestPermission, package:firebase_messaging/firebase_messaging.dart, package:permission_handler/permission_handler.dart

### Community 90 - "onboarding_preview.dart"
Cohesion: 0.33
Nodes (5): build, main, _PreviewApp, package:flutter/foundation.dart, ../screens/onboarding_flow_screen.dart

### Community 91 - "firebase_options.dart"
Cohesion: 0.22
Nodes (8): android, DefaultFirebaseOptions, ios, macos, web, windows, package:firebase_core/firebase_core.dart, static const FirebaseOptions

## Ambiguous Edges - Review These
- `One Screen Per File Rule` → `Graphify Skill Trigger`  [AMBIGUOUS]
  .claude/CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **640 isolated node(s):** `AR`, `AURORA`, `C`, `S`, `R` (+635 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `One Screen Per File Rule` and `Graphify Skill Trigger`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `AuthErrorInfo` connect `forgot_password_sheet.dart` to `sign_in_page.dart`, `sign_up_screen.dart`, `auth_error_mapper.dart`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **Why does `_OtpVerificationScreenState` connect `State` to `otp_verification_screen.dart`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **What connects `AR`, `AURORA`, `C` to the rest of the system?**
  _640 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `sign_in_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03225806451612903 - nodes in this community are weakly interconnected._
- **Should `sign_up_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.037037037037037035 - nodes in this community are weakly interconnected._
- **Should `otp_verification_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.043478260869565216 - nodes in this community are weakly interconnected._