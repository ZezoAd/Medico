# Graph Report - medico  (2026-08-23)

## Corpus Check
- 76 files · ~40,873 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 996 nodes · 1225 edges · 92 communities (47 shown, 45 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 21 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `941db03f`
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
- sign_up_screen_test.dart
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
- home_screen.dart
- MainActivity.kt
- One Screen Per File Rule
- FlView
- Dart analyzer configuration
- onboarding_step1_basics.dart
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
- auth_gate.dart
- onboarding_sync_service.dart
- onboarding_step_scaffold.dart
- package:flutter/material.dart
- aurora_select_field.dart
- package:supabase_flutter/supabase_flutter.dart
- Auth Fallback Chain
- State
- notification_service.dart
- signup_verified Gate
- onboarding_preview.dart
- SignUpScreen

## God Nodes (most connected - your core abstractions)
1. `usePress()` - 7 edges
2. `AppDelegate` - 5 edges
3. `signup_verified Gate` - 5 edges
4. `Password Reset Web Page` - 5 edges
5. `Recovery Token Verification` - 5 edges
6. `FlutterMacOS` - 4 edges
7. `OnboardingData` - 4 edges
8. `_OnboardingCompletionScreenState` - 4 edges
9. `_OnboardingStep3NotificationsState` - 4 edges
10. `OtpVerificationScreen` - 4 edges

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

## Communities (92 total, 45 thin omitted)

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
Nodes (34): Any, app_links, Cocoa, connectivity_plus, firebase_core, firebase_crashlytics, firebase_messaging, Flutter (+26 more)

### Community 5 - "auth_error_mapper.dart"
Cohesion: 0.06
Nodes (33): accountAlreadyExistsMessage, any, AuthErrorInfo, code, _codeMessages, doctorTabGoogleCreatedPatientMessage, doctorTabNotADoctorAccountMessage, emailNotConfirmedMessage (+25 more)

### Community 6 - "forgot_password_sheet.dart"
Cohesion: 0.06
Nodes (33): auth_error_banner.dart, AuthErrorInfo?, Aurora Sheet Design System, Password Policy: 8 Chars, No Composition Rule, _GradientBackdrop, _banner, build, _cooldown (+25 more)

### Community 7 - "sign_up_screen_test.dart"
Cohesion: 0.06
Nodes (29): Checkbox, package:flutter_test/flutter_test.dart, package:medico/main.dart, package:medico/models/onboarding_data.dart, package:medico/screens/sign_in_page.dart, package:medico/screens/sign_up_screen.dart, package:medico/services/onboarding_sync_service.dart, package:shared_preferences/shared_preferences.dart (+21 more)

### Community 8 - "main.dart"
Cohesion: 0.09
Nodes (21): android, DefaultFirebaseOptions, ios, macos, web, windows, build, buildOverscrollIndicator (+13 more)

### Community 10 - "auth_error_banner.dart"
Cohesion: 0.09
Nodes (22): AuthErrorBanner, _AuthErrorBannerState, AuthErrorSeverity, autoDismiss, _autoDismissDelay, _autoDismissTimer, build, createState (+14 more)

### Community 11 - "user_profile.dart"
Cohesion: 0.07
Nodes (26): bool get, int?, arabicLabel, birthYear, city, copyWith, fromText, hasCity (+18 more)

### Community 12 - "StatelessWidget"
Cohesion: 0.15
Nodes (13): _GateLoading, _GateRetry, _SoftCircle, _GradientBackdrop, _SoftCircle, _GradientBackdrop, _SoftCircle, _CardContent (+5 more)

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

### Community 18 - "home_screen.dart"
Cohesion: 0.18
Nodes (11): bookings_tab.dart, browse_tab.dart, home_tab.dart, build, createState, HomeScreen, _HomeScreenState, _tabIndex (+3 more)

### Community 26 - "onboarding_step1_basics.dart"
Cohesion: 0.06
Nodes (34): Gender, build, _canSlide, createState, didUpdateWidget, initState, OnboardingGenderControl, _OnboardingGenderControlState (+26 more)

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
Cohesion: 0.07
Nodes (27): build, _completionStep, createState, _data, dispose, _enableNotifications, _finish, _goTo (+19 more)

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
Cohesion: 0.11
Nodes (17): AuroraIconButton, AuroraPrimaryButton, AuroraSecondaryButton, AuroraSectionTitle, build, child, createState, _enabled (+9 more)

### Community 74 - "onboarding_step_header.dart"
Cohesion: 0.17
Nodes (11): build, _height, _markGap, _markHeight, _MedicoMark, OnboardingStepHeader, step, _topPadding (+3 more)

### Community 75 - "queue_status_card_preview.dart"
Cohesion: 0.18
Nodes (10): DateTime, build, createState, initState, main, _recordedAt, _setStatus, _status (+2 more)

### Community 76 - "_OnboardingCompletionScreenState"
Cohesion: 0.40
Nodes (5): OnboardingCompletionScreen, _OnboardingCompletionScreenState, OnboardingStep3Notifications, _OnboardingStep3NotificationsState, SingleTickerProviderStateMixin

### Community 80 - "auth_gate.dart"
Cohesion: 0.08
Nodes (24): AuthGate, _AuthGateState, build, _connectivitySub, createState, dispose, _drainPendingOnboarding, _failClosed (+16 more)

### Community 81 - "onboarding_sync_service.dart"
Cohesion: 0.11
Nodes (18): dart:convert, clearPending, clearProgress, data, hasPending, _key, loadProgress, _maxStep (+10 more)

### Community 82 - "onboarding_step_scaffold.dart"
Cohesion: 0.12
Nodes (15): build, children, footer, helperText, OnboardingStepFooter, OnboardingStepScaffold, onPrimary, onSkip (+7 more)

### Community 83 - "package:flutter/material.dart"
Cohesion: 0.18
Nodes (10): BookingsTab, build, BrowseTab, build, build, HomeTab, build, SettingsTab (+2 more)

### Community 84 - "aurora_select_field.dart"
Cohesion: 0.18
Nodes (10): aurora_buttons.dart, IconData, AuroraSelectField, build, icon, onTap, placeholder, subtitle (+2 more)

### Community 85 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.20
Nodes (8): OnboardingService, saveOnboarding, fetchCurrentProfile, ProfileService, ../models/onboarding_data.dart, ../models/user_profile.dart, package:flutter/foundation.dart, package:supabase_flutter/supabase_flutter.dart

### Community 86 - "Auth Fallback Chain"
Cohesion: 0.28
Nodes (9): Google G Logo Mark, Auth Fallback Chain, OtpVerificationScreen, _OtpVerificationScreenState, flutter_svg Dependency, google_sign_in Dependency, medico Flutter Package, pinput Dependency (+1 more)

### Community 87 - "State"
Cohesion: 0.28
Nodes (9): _PreviewApp, _PreviewAppState, AuroraPressable, _AuroraPressableState, QueueStatusCard, _QueueStatusCardState, State, StatefulWidget (+1 more)

### Community 88 - "notification_service.dart"
Cohesion: 0.29
Nodes (6): dart:io, NotificationService, registerDeviceToken, requestPermission, package:firebase_messaging/firebase_messaging.dart, package:permission_handler/permission_handler.dart

### Community 89 - "signup_verified Gate"
Cohesion: 0.40
Nodes (6): signup_verified Gate, signupVerified, OtpPurpose, markSignupVerified, Recovery Token Verification, JS-Execution Scanner Defense

### Community 90 - "onboarding_preview.dart"
Cohesion: 0.40
Nodes (4): build, main, _PreviewApp, ../screens/onboarding_flow_screen.dart

## Ambiguous Edges - Review These
- `One Screen Per File Rule` → `Graphify Skill Trigger`  [AMBIGUOUS]
  .claude/CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **628 isolated node(s):** `_GateStatus`, `_fetchTimeout`, `_sync`, `_connectivitySub`, `_onboardingComplete` (+623 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **45 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `One Screen Per File Rule` and `Graphify Skill Trigger`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `_OtpVerificationScreenState` connect `Auth Fallback Chain` to `otp_verification_screen.dart`, `State`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **Why does `Password Reset Web Page` connect `forgot_password_sheet.dart` to `signup_verified Gate`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **Why does `OtpVerificationScreen` connect `Auth Fallback Chain` to `otp_verification_screen.dart`, `State`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **What connects `_GateStatus`, `_fetchTimeout`, `_sync` to the rest of the system?**
  _628 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `sign_in_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03125 - nodes in this community are weakly interconnected._
- **Should `sign_up_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.037037037037037035 - nodes in this community are weakly interconnected._