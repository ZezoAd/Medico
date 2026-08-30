# Graph Report - medico  (2026-08-26)

## Corpus Check
- 88 files · ~57,692 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1234 nodes · 1623 edges · 73 communities (65 shown, 8 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `7ae605fa`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- auth_surface.dart
- ConnectivityArchitecture.jsx
- sign_up_screen.dart
- otp_verification_screen.dart
- GeneratedPluginRegistrant.swift
- auth_error_mapper.dart
- forgot_password_sheet.dart
- profile_tab_test.dart
- main.dart
- onboarding_milestone_stepper.dart
- auth_error_banner.dart
- user_profile.dart
- StatelessWidget
- aurora_tokens.dart
- onboarding_sync_service.dart
- manifest.json
- queue_status_card.dart
- onboarding_v6.jsx
- onboarding_city_picker_sheet.dart
- MainActivity.kt
- package:flutter/material.dart
- profile_tab.dart
- Dart analyzer configuration
- onboarding_gender_control.dart
- Flutter DevTools configuration
- iOS LaunchImage asset instructions
- home_specialty_chips.dart
- medico project README
- Flutter web index.html entrypoint
- home_specialty_chips_test.dart
- welcome_screen.dart
- Auth Fallback Chain
- auth_test_support.dart
- otp_verification_screen_test.dart
- sign_up_screen_test.dart
- onboarding_progress_test.dart
- sign_in_screen_test.dart
- notification_service.dart
- Recovery Token Verification
- ../models/onboarding_data.dart
- package:supabase_flutter/supabase_flutter.dart
- home_tab.dart
- sign_in_screen.dart
- onboarding_step3_notifications.dart
- queue_status_card_preview.dart
- home_empty_state_card_preview.dart
- onboarding_step1_basics.dart
- onboarding_step_header.dart
- VoidCallback
- Password Reset Web Page
- State
- _OnboardingCompletionScreenState
- _codeMessages
- gender_avatar.dart
- MaterialPageRoute
- One Screen Per File Rule
- StatefulWidget
- ../theme/aurora_tokens.dart
- arabic_formatting.dart
- auth_gate.dart
- wait_estimate.dart
- SignUpScreen
- onboarding_flow_screen.dart
- onboarding_completion_screen.dart
- onboarding_year_picker_sheet.dart
- home_empty_state_card.dart
- aurora_buttons.dart
- auth_gate.dart
- home_screen.dart

## God Nodes (most connected - your core abstractions)
1. `usePress()` - 7 edges
2. `AppDelegate` - 5 edges
3. `Gender` - 5 edges
4. `OnboardingData` - 5 edges
5. `SignUpScreen` - 5 edges
6. `Password Reset Web Page` - 5 edges
7. `Recovery Token Verification` - 5 edges
8. `_OnboardingCompletionScreenState` - 4 edges
9. `_OnboardingStep3NotificationsState` - 4 edges
10. `OtpVerificationScreen` - 4 edges

## Surprising Connections (you probably didn't know these)
- `ERROR_CODE_MESSAGES` --semantically_similar_to--> `_codeMessages`  [INFERRED] [semantically similar]
  web/reset-password/index.html → lib/utils/auth_error_mapper.dart
- `mapUpdatePasswordError` --semantically_similar_to--> `mapAuthError`  [INFERRED] [semantically similar]
  web/reset-password/index.html → lib/utils/auth_error_mapper.dart
- `signup_verified Gate` --references--> `signupVerified`  [INFERRED]
  CLAUDE.md → lib/models/user_profile.dart
- `Recovery Token Verification` --conceptually_related_to--> `signupVerified`  [INFERRED]
  web/reset-password/index.html → lib/models/user_profile.dart
- `Recovery Token Verification` --conceptually_related_to--> `OtpPurpose`  [INFERRED]
  web/reset-password/index.html → lib/screens/otp_verification_screen.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Reset Page Screen State Machine** — web_reset_password_index_page, web_reset_password_index_screens, web_reset_password_index_showscreen, web_reset_password_index_showfatalerror [EXTRACTED 1.00]
- **Arabic Auth Error Copy (Dart + JS, no shared code)** — web_reset_password_index_mapupdatepassworderror, web_reset_password_index_error_code_messages, lib_utils_auth_error_mapper_mapautherror, lib_utils_auth_error_mapper_codemessages [INFERRED 0.85]

## Communities (73 total, 8 thin omitted)

### Community 0 - "auth_surface.dart"
Cohesion: 0.04
Nodes (51): EdgeInsets, FocusNode, actionLabel, authSheetRadius, body, build, center, child (+43 more)

### Community 1 - "ConnectivityArchitecture.jsx"
Cohesion: 0.29
Nodes (4): AR, AURORA, clock(), ConnectivityArchitecture()

### Community 2 - "sign_up_screen.dart"
Cohesion: 0.05
Nodes (38): Color get, _agreedToTerms, _banner, build, _buildBanner, _buildTermsRow, cameFromSignIn, createState (+30 more)

### Community 3 - "otp_verification_screen.dart"
Cohesion: 0.05
Nodes (38): _bannerRetry, build, _buildForm, _buildHero, _buildPasswordUnchangedNote, _buildPinInput, _buildResendBlock, _buildSpamHint (+30 more)

### Community 4 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (33): Any, app_links, Cocoa, connectivity_plus, firebase_core, firebase_crashlytics, firebase_messaging, Flutter (+25 more)

### Community 5 - "auth_error_mapper.dart"
Cohesion: 0.07
Nodes (26): accountAlreadyExistsMessage, any, code, emailNotConfirmedMessage, error, genericAuthErrorMessage, isEmailNotConfirmedError, isInvalidCredentialsError (+18 more)

### Community 6 - "forgot_password_sheet.dart"
Cohesion: 0.08
Nodes (24): auth_error_banner.dart, AuthErrorInfo, _banner, build, _cooldown, _cooldownSeconds, _cooldownTimer, createState (+16 more)

### Community 7 - "profile_tab_test.dart"
Cohesion: 0.18
Nodes (10): package:flutter/rendering.dart, package:medico/screens/home_tab.dart, package:medico/screens/profile_tab.dart, RenderParagraph, _host, isSignedIn, main, _narrow (+2 more)

### Community 8 - "main.dart"
Cohesion: 0.09
Nodes (21): android, DefaultFirebaseOptions, ios, macos, web, windows, build, buildOverscrollIndicator (+13 more)

### Community 9 - "onboarding_milestone_stepper.dart"
Cohesion: 0.12
Nodes (16): build, _column, _half, height, index, isActive, isDone, _labelGap (+8 more)

### Community 10 - "auth_error_banner.dart"
Cohesion: 0.09
Nodes (23): dart:async, AuthErrorBanner, _AuthErrorBannerState, AuthErrorSeverity, autoDismiss, _autoDismissDelay, _autoDismissTimer, build (+15 more)

### Community 11 - "user_profile.dart"
Cohesion: 0.07
Nodes (28): bool get, int?, arabicLabel, birthYear, city, copyWith, fromText, hasCity (+20 more)

### Community 12 - "StatelessWidget"
Cohesion: 0.07
Nodes (28): AuthBackButton, AuthBackdrop, AuthFieldLabel, AuthFooterPrompt, AuthGoogleButton, AuthHero, AuthInlineError, AuthOrDivider (+20 more)

### Community 13 - "aurora_tokens.dart"
Cohesion: 0.03
Nodes (79): aurora, AuroraColors, AuroraFontSize, AuroraGradients, AuroraMotion, AuroraRadius, AuroraShadows, AuroraSpacing (+71 more)

### Community 14 - "onboarding_sync_service.dart"
Cohesion: 0.11
Nodes (18): dart:convert, clearPending, clearProgress, data, hasPending, _key, loadProgress, _maxStep (+10 more)

### Community 15 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 16 - "queue_status_card.dart"
Cohesion: 0.04
Nodes (44): avgConsultMinutes, _blobControllers, _blobDurations, build, card, connectionStatus, controller, createState (+36 more)

### Community 17 - "onboarding_v6.jsx"
Cohesion: 0.07
Nodes (21): bodyFont, C, CURRENT_YEAR, displayFont, E, F, GOVERNORATES, InlineSkipButton() (+13 more)

### Community 18 - "onboarding_city_picker_sheet.dart"
Cohesion: 0.12
Nodes (17): build, _CityPickerSheet, _CityPickerSheetState, _CityRow, createState, current, dispose, kGovernorates (+9 more)

### Community 20 - "package:flutter/material.dart"
Cohesion: 0.25
Nodes (6): BrowseTab, build, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:medico/main.dart, main

### Community 21 - "profile_tab.dart"
Cohesion: 0.07
Nodes (29): build, busy, contact, createState, email, enabled, _fallbackContact, _fallbackName (+21 more)

### Community 26 - "onboarding_gender_control.dart"
Cohesion: 0.15
Nodes (13): build, _canSlide, createState, didUpdateWidget, initState, OnboardingGenderControl, _OnboardingGenderControlState, onChanged (+5 more)

### Community 30 - "home_specialty_chips.dart"
Cohesion: 0.10
Nodes (20): @immutable, FaIconData, build, createState, HomeSpecialtyChips, _HomeSpecialtyChipsState, icon, isDark (+12 more)

### Community 33 - "home_specialty_chips_test.dart"
Cohesion: 0.12
Nodes (16): package:medico/widgets/home_empty_state_card.dart, package:medico/widgets/home_specialty_chips.dart, chipRow, descendant, dragUntilVisible, ensureVisible, labels, main (+8 more)

### Community 34 - "welcome_screen.dart"
Cohesion: 0.09
Nodes (23): _BrandMark, _BrandPanel, build, createState, _CrossBar, _forwarding, height, initialErrorMessage (+15 more)

### Community 35 - "Auth Fallback Chain"
Cohesion: 0.28
Nodes (9): Google G Logo Mark, Auth Fallback Chain, OtpVerificationScreen, _OtpVerificationScreenState, flutter_svg Dependency, google_sign_in Dependency, medico Flutter Package, pinput Dependency (+1 more)

### Community 36 - "auth_test_support.dart"
Cohesion: 0.12
Nodes (16): DecoratedBox, arabicIndic, decorated, dpr, expectNoArabicIndicDigits, heroGradientOf, keyboardInset, phone (+8 more)

### Community 37 - "otp_verification_screen_test.dart"
Cohesion: 0.15
Nodes (12): Directionality, AuthPrimaryButton, package:medico/screens/otp_verification_screen.dart, package:pinput/pinput.dart, Pinput, Size, _email, keyboardInset (+4 more)

### Community 38 - "sign_up_screen_test.dart"
Cohesion: 0.12
Nodes (15): AnimatedContainer, Checkbox, NavigatorObserver, _RouteCounter, agreeToTerms, depth, didPop, didPush (+7 more)

### Community 39 - "onboarding_progress_test.dart"
Cohesion: 0.25
Nodes (7): package:medico/models/onboarding_data.dart, package:medico/services/onboarding_sync_service.dart, package:shared_preferences/shared_preferences.dart, main, service, userA, userB

### Community 40 - "sign_in_screen_test.dart"
Cohesion: 0.11
Nodes (20): auth_test_support.dart, NavigatorState, package:medico/screens/sign_in_screen.dart, package:medico/screens/sign_up_screen.dart, package:medico/screens/welcome_screen.dart, package:medico/theme/aurora_tokens.dart, package:medico/widgets/auth_surface.dart, budgetAndroid (+12 more)

### Community 41 - "notification_service.dart"
Cohesion: 0.29
Nodes (6): dart:io, NotificationService, registerDeviceToken, requestPermission, package:firebase_messaging/firebase_messaging.dart, package:permission_handler/permission_handler.dart

### Community 42 - "Recovery Token Verification"
Cohesion: 0.40
Nodes (6): signup_verified Gate, signupVerified, OtpPurpose, markSignupVerified, Recovery Token Verification, JS-Execution Scanner Defense

### Community 43 - "../models/onboarding_data.dart"
Cohesion: 0.20
Nodes (8): build, main, _PreviewApp, OnboardingService, saveOnboarding, ../models/onboarding_data.dart, package:flutter/foundation.dart, ../screens/onboarding_flow_screen.dart

### Community 44 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.40
Nodes (4): fetchCurrentProfile, ProfileService, ../models/user_profile.dart, package:supabase_flutter/supabase_flutter.dart

### Community 45 - "home_tab.dart"
Cohesion: 0.17
Nodes (12): _bellSize, build, createState, height, HomeTab, _HomeTabState, _HomeTopBar, _NotificationBell (+4 more)

### Community 46 - "sign_in_screen.dart"
Cohesion: 0.05
Nodes (38): _banner, _bannerAction, _bannerActionLabel, build, _buildBanner, _clearBanner, createState, _credentialsError (+30 more)

### Community 47 - "onboarding_step3_notifications.dart"
Cohesion: 0.10
Nodes (19): Animation, AnimationController, class, build, _Chip, _ChipRow, _chips, createState (+11 more)

### Community 48 - "queue_status_card_preview.dart"
Cohesion: 0.15
Nodes (12): DateTime, build, createState, label, main, _recordedAt, _Scenario, _setScenario (+4 more)

### Community 49 - "home_empty_state_card_preview.dart"
Cohesion: 0.18
Nodes (10): Brightness, brightness, build, child, createState, _Forced, label, main (+2 more)

### Community 50 - "onboarding_step1_basics.dart"
Cohesion: 0.17
Nodes (11): build, data, OnboardingStep1Basics, onChanged, onContinue, onSkip, _pickYear, onboarding_gender_control.dart (+3 more)

### Community 51 - "onboarding_step_header.dart"
Cohesion: 0.18
Nodes (10): build, _height, _markGap, _markHeight, _MedicoMark, OnboardingStepHeader, step, _topPadding (+2 more)

### Community 52 - "VoidCallback"
Cohesion: 0.20
Nodes (9): build, data, OnboardingStep2City, onChanged, onContinue, _pickCity, onboarding_city_picker_sheet.dart, VoidCallback (+1 more)

### Community 53 - "Password Reset Web Page"
Cohesion: 0.22
Nodes (9): Aurora Sheet Design System, Password Policy: 8 Chars, No Composition Rule, _resetPasswordRedirect, _validateEmail, Password Reset Web Page, screens Element Map, showFatalError, showScreen (+1 more)

### Community 54 - "State"
Cohesion: 0.28
Nodes (9): _PreviewAppState, _PreviewAppState, HomeEmptyStateCard, _HomeEmptyStateCardState, QueueStatusCard, _QueueStatusCardState, _PreviewApp, State (+1 more)

### Community 55 - "_OnboardingCompletionScreenState"
Cohesion: 0.40
Nodes (5): OnboardingCompletionScreen, _OnboardingCompletionScreenState, OnboardingStep3Notifications, _OnboardingStep3NotificationsState, SingleTickerProviderStateMixin

### Community 56 - "_codeMessages"
Cohesion: 0.50
Nodes (4): _codeMessages, mapAuthError, ERROR_CODE_MESSAGES, mapUpdatePasswordError

### Community 57 - "gender_avatar.dart"
Cohesion: 0.20
Nodes (9): Gender, build, colorFor, _discAlpha, filled, gender, GenderAvatar, size (+1 more)

### Community 58 - "MaterialPageRoute"
Cohesion: 0.25
Nodes (8): _goSignUp, _resendConfirmation, _handleSubmit, _forwardToSignIn, _goSignIn, _goSignUp, MaterialPageRoute, main

### Community 60 - "StatefulWidget"
Cohesion: 0.29
Nodes (7): _PreviewApp, _PreviewApp, AuthGate, _AuthGateState, AuthTextField, _AuthTextFieldState, StatefulWidget

### Community 61 - "../theme/aurora_tokens.dart"
Cohesion: 0.50
Nodes (3): BookingsTab, build, ../theme/aurora_tokens.dart

### Community 62 - "arabic_formatting.dart"
Cohesion: 0.11
Nodes (18): buffer, CountedParts, digits, _easternArabicDigits, formatArabicClock12, hour12, hour24, _joinParts (+10 more)

### Community 63 - "auth_gate.dart"
Cohesion: 0.50
Nodes (3): auth_gate.dart, build, SplashScreen

### Community 64 - "wait_estimate.dart"
Cohesion: 0.20
Nodes (9): arabic_formatting.dart, add, estimatedTurnTime, high, low, _roundToNearest5, total, totalWaitMinutes (+1 more)

### Community 67 - "onboarding_flow_screen.dart"
Cohesion: 0.06
Nodes (33): home_screen.dart, build, _completionStep, createState, _data, dispose, _enableNotifications, _finish (+25 more)

### Community 68 - "onboarding_completion_screen.dart"
Cohesion: 0.08
Nodes (23): CustomPainter, dart:ui, _badgeScale, _Blob, _blobBlue, build, _buttonFade, _checkDraw (+15 more)

### Community 69 - "onboarding_year_picker_sheet.dart"
Cohesion: 0.10
Nodes (21): FixedExtentScrollController, build, _controller, createState, dispose, _firstYear, initial, initState (+13 more)

### Community 71 - "home_empty_state_card.dart"
Cohesion: 0.09
Nodes (21): Color, _blobControllers, _blobDurations, build, controller, createState, _ctaInk, didChangeDependencies (+13 more)

### Community 73 - "aurora_buttons.dart"
Cohesion: 0.05
Nodes (43): aurora_buttons.dart, IconData, build, children, footer, helperText, OnboardingStepFooter, OnboardingStepScaffold (+35 more)

### Community 80 - "auth_gate.dart"
Cohesion: 0.07
Nodes (26): build, _connectivitySub, createState, dispose, _drainPendingOnboarding, _failClosed, _fetchTimeout, _GateLoading (+18 more)

### Community 85 - "home_screen.dart"
Cohesion: 0.12
Nodes (16): bookings_tab.dart, browse_tab.dart, home_tab.dart, build, createState, _email, HomeScreen, _HomeScreenState (+8 more)

## Ambiguous Edges - Review These
- `One Screen Per File Rule` → `Graphify Skill Trigger`  [AMBIGUOUS]
  .claude/CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **795 isolated node(s):** `AR`, `AURORA`, `C`, `S`, `R` (+790 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `One Screen Per File Rule` and `Graphify Skill Trigger`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Recovery Token Verification` connect `Recovery Token Verification` to `Password Reset Web Page`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `OtpPurpose` connect `Recovery Token Verification` to `otp_verification_screen.dart`, `sign_in_screen.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `AuthErrorInfo` connect `forgot_password_sheet.dart` to `sign_up_screen.dart`, `auth_error_mapper.dart`, `sign_in_screen.dart`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **What connects `AR`, `AURORA`, `C` to the rest of the system?**
  _795 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `auth_surface.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.038461538461538464 - nodes in this community are weakly interconnected._
- **Should `sign_up_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05128205128205128 - nodes in this community are weakly interconnected._