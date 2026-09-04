# Graph Report - medico  (2026-09-04)

## Corpus Check
- 102 files · ~92,107 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1619 nodes · 2143 edges · 94 communities (80 shown, 14 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b599e4de`
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
- home_specialty_doctors.dart
- auth_error_banner.dart
- user_profile.dart
- StatelessWidget
- aurora_tokens.dart
- onboarding_sync_service.dart
- manifest.json
- queue_status_card.dart
- onboarding_v6.jsx
- home_specialty_chips.dart
- MainActivity.kt
- onboarding_step3_notifications.dart
- profile_tab.dart
- Dart analyzer configuration
- onboarding_gender_control.dart
- Flutter DevTools configuration
- iOS LaunchImage asset instructions
- State
- medico project README
- Flutter web index.html entrypoint
- home_specialty_chips_test.dart
- welcome_screen.dart
- Auth Fallback Chain
- auth_test_support.dart
- otp_verification_screen_test.dart
- AnimatedOpacity
- theme_service.dart
- home_specialty_doctors_preview.dart
- offline_status_capsule.dart
- Recovery Token Verification
- package:flutter/foundation.dart
- package:supabase_flutter/supabase_flutter.dart
- home_specialty_doctors_test.dart
- sign_in_screen.dart
- home_tab.dart
- queue_status_card_preview.dart
- home_empty_state_card_preview.dart
- onboarding_step1_basics.dart
- theme_test.dart
- app_theme.dart
- onboarding_step_scaffold.dart
- theme_picker_sheet.dart
- offline_status_capsule_test.dart
- session_expiry_test.dart
- VoidCallback
- MaterialPageRoute
- One Screen Per File Rule
- package:flutter/material.dart
- sign_up_screen_test.dart
- arabic_formatting.dart
- sign_in_screen_test.dart
- wait_estimate.dart
- auth_gate.dart
- AuroraPaletteContext
- onboarding_flow_screen.dart
- onboarding_completion_screen.dart
- onboarding_year_picker_sheet.dart
- onboarding_milestone_stepper.dart
- home_empty_state_card.dart
- connectivity_service.dart
- aurora_buttons.dart
- package:flutter_test/flutter_test.dart
- Password Reset Web Page
- fake_connectivity.dart
- welcome_screen_test.dart
- firebase_options.dart
- inline_error_overflow_test.dart
- auth_gate.dart
- static const
- dart:async
- NavigatorObserver
- ../widgets/global_offline_strip.dart
- home_screen.dart
- Doctor
- notification_service.dart
- package:medico/widgets/global_offline_strip.dart
- _OnboardingCompletionScreenState
- _codeMessages
- ../models/doctor.dart
- ThemeMode
- package:medico/widgets/queue_status_card.dart

## God Nodes (most connected - your core abstractions)
1. `usePress()` - 7 edges
2. `AuroraPalette` - 5 edges
3. `AppDelegate` - 5 edges
4. `Gender` - 5 edges
5. `OnboardingData` - 5 edges
6. `SignUpScreen` - 5 edges
7. `AuthTextField` - 5 edges
8. `Password Reset Web Page` - 5 edges
9. `Recovery Token Verification` - 5 edges
10. `_HomeScreenState` - 4 edges

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

## Communities (94 total, 14 thin omitted)

### Community 0 - "auth_surface.dart"
Cohesion: 0.03
Nodes (58): EdgeInsets, FocusNode, actionLabel, authSheetRadius, body, build, center, child (+50 more)

### Community 1 - "ConnectivityArchitecture.jsx"
Cohesion: 0.29
Nodes (4): AR, AURORA, clock(), ConnectivityArchitecture()

### Community 2 - "sign_up_screen.dart"
Cohesion: 0.05
Nodes (37): _agreedToTerms, _banner, build, _buildBanner, _buildTermsRow, cameFromSignIn, createState, dispose (+29 more)

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
Cohesion: 0.12
Nodes (15): build, buildOverscrollIndicator, init, initializeApp, load, main, MedicoApp, _NoStretchScrollBehavior (+7 more)

### Community 9 - "home_specialty_doctors.dart"
Cohesion: 0.05
Nodes (42): ../dev/mock_doctors.dart, allSpecialtiesCap, allSpecialtiesKey, _avatarSize, _BookButton, build, _cache, _cachedEpoch (+34 more)

### Community 10 - "auth_error_banner.dart"
Cohesion: 0.09
Nodes (22): AuthErrorBanner, _AuthErrorBannerState, AuthErrorSeverity, autoDismiss, _autoDismissDelay, _autoDismissTimer, build, createState (+14 more)

### Community 11 - "user_profile.dart"
Cohesion: 0.04
Nodes (44): bool get, double?, int?, clinicName, id, name, photoUrl, rating (+36 more)

### Community 12 - "StatelessWidget"
Cohesion: 0.08
Nodes (25): AuthBackButton, AuthBackdrop, AuthCollapsible, AuthFieldLabel, AuthFooterPrompt, AuthGoogleButton, AuthHero, AuthInlineError (+17 more)

### Community 13 - "aurora_tokens.dart"
Cohesion: 0.02
Nodes (96): AuroraPalette get, BoxBorder?, accentOnTonal, accentOnTonalDark, aurora, AuroraColors, AuroraFontSize, AuroraGradients (+88 more)

### Community 14 - "onboarding_sync_service.dart"
Cohesion: 0.11
Nodes (17): dart:convert, clearPending, clearProgress, data, hasPending, _key, loadProgress, _maxStep (+9 more)

### Community 15 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 16 - "queue_status_card.dart"
Cohesion: 0.04
Nodes (45): avgConsultMinutes, _blobControllers, _blobDurations, build, card, connectionStatus, controller, createState (+37 more)

### Community 17 - "onboarding_v6.jsx"
Cohesion: 0.07
Nodes (21): bodyFont, C, CURRENT_YEAR, displayFont, E, F, GOVERNORATES, InlineSkipButton() (+13 more)

### Community 18 - "home_specialty_chips.dart"
Cohesion: 0.09
Nodes (23): @immutable, FaIconData, home_specialty_doctors.dart, Doctor, AuroraPalette, build, createState, HomeSpecialtyChips (+15 more)

### Community 20 - "onboarding_step3_notifications.dart"
Cohesion: 0.10
Nodes (19): Animation, AnimationController, class, build, _Chip, _ChipRow, _chips, createState (+11 more)

### Community 21 - "profile_tab.dart"
Cohesion: 0.06
Nodes (31): build, busy, contact, createState, email, enabled, _fallbackContact, _fallbackName (+23 more)

### Community 26 - "onboarding_gender_control.dart"
Cohesion: 0.15
Nodes (13): build, _canSlide, createState, didUpdateWidget, initState, OnboardingGenderControl, _OnboardingGenderControlState, onChanged (+5 more)

### Community 30 - "State"
Cohesion: 0.25
Nodes (8): _PreviewAppState, HomeScreen, _HomeScreenState, HomeTab, _HomeTabState, _PreviewApp, State, WidgetsBindingObserver

### Community 33 - "home_specialty_chips_test.dart"
Cohesion: 0.12
Nodes (16): package:medico/widgets/home_empty_state_card.dart, chipLabel, chipRow, connectivity, descendant, dragUntilVisible, ensureVisible, labels (+8 more)

### Community 34 - "welcome_screen.dart"
Cohesion: 0.09
Nodes (23): _BrandMark, _BrandPanel, build, createState, _CrossBar, _forwarding, height, initialErrorMessage (+15 more)

### Community 35 - "Auth Fallback Chain"
Cohesion: 0.28
Nodes (9): Google G Logo Mark, Auth Fallback Chain, OtpVerificationScreen, _OtpVerificationScreenState, flutter_svg Dependency, google_sign_in Dependency, medico Flutter Package, pinput Dependency (+1 more)

### Community 36 - "auth_test_support.dart"
Cohesion: 0.07
Nodes (27): arabicIndic, decorated, dpr, expectFieldClearOfKeyboard, expectNoArabicIndicDigits, false, heroGradientOf, inset (+19 more)

### Community 37 - "otp_verification_screen_test.dart"
Cohesion: 0.15
Nodes (12): Directionality, AuthPrimaryButton, package:medico/screens/otp_verification_screen.dart, package:pinput/pinput.dart, Pinput, Size, _email, keyboardInset (+4 more)

### Community 39 - "theme_service.dart"
Cohesion: 0.20
Nodes (9): init, instance, _key, load, save, service, setMode, ThemeService (+1 more)

### Community 40 - "home_specialty_doctors_preview.dart"
Cohesion: 0.12
Nodes (16): AppThemeVariant, build, child, createState, _EdgeCaseRow, _edgeCases, _Forced, label (+8 more)

### Community 41 - "offline_status_capsule.dart"
Cohesion: 0.04
Nodes (48): actionFill, actionIcon, actionSize, build, _CapsuleCard, _CapsulePalette, cardKey, _CircleBadge (+40 more)

### Community 42 - "Recovery Token Verification"
Cohesion: 0.40
Nodes (6): signup_verified Gate, signupVerified, OtpPurpose, markSignupVerified, Recovery Token Verification, JS-Execution Scanner Defense

### Community 43 - "package:flutter/foundation.dart"
Cohesion: 0.33
Nodes (5): build, main, _PreviewApp, package:flutter/foundation.dart, ../screens/onboarding_flow_screen.dart

### Community 44 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.40
Nodes (4): fetchCurrentProfile, ProfileService, ../models/user_profile.dart, package:supabase_flutter/supabase_flutter.dart

### Community 45 - "home_specialty_doctors_test.dart"
Cohesion: 0.08
Nodes (24): DoctorCard, HomeSpecialtyDoctors, package:medico/dev/mock_doctors.dart, package:medico/models/doctor.dart, package:medico/widgets/home_specialty_doctors.dart, ScrollableState, fake, _longName (+16 more)

### Community 46 - "sign_in_screen.dart"
Cohesion: 0.05
Nodes (37): _banner, _bannerAction, _bannerActionLabel, build, _buildBanner, _clearBanner, createState, _credentialsError (+29 more)

### Community 47 - "home_tab.dart"
Cohesion: 0.09
Nodes (22): ConnectivityPhase, ConnectivityService, _bellSize, build, connectivityService, createState, dispose, _handleRefresh (+14 more)

### Community 48 - "queue_status_card_preview.dart"
Cohesion: 0.13
Nodes (15): DateTime, build, createState, label, main, _PreviewApp, _PreviewAppState, _recordedAt (+7 more)

### Community 49 - "home_empty_state_card_preview.dart"
Cohesion: 0.13
Nodes (14): AppThemeVariant, AppThemeVariant, build, child, createState, _Forced, label, main (+6 more)

### Community 50 - "onboarding_step1_basics.dart"
Cohesion: 0.09
Nodes (23): OnboardingData, build, data, OnboardingStep1Basics, onChanged, onContinue, onSkip, _pickYear (+15 more)

### Community 51 - "theme_test.dart"
Cohesion: 0.15
Nodes (12): Brightness, DecoratedBox, package:medico/services/theme_service.dart, package:medico/theme/app_theme.dart, package:medico/widgets/home_specialty_chips.dart, _host, inner, main (+4 more)

### Community 52 - "app_theme.dart"
Cohesion: 0.20
Nodes (9): aurora_tokens.dart, AppTheme, _build, dark, light, lightScaffoldBackground, _textTheme, package:google_fonts/google_fonts.dart (+1 more)

### Community 53 - "onboarding_step_scaffold.dart"
Cohesion: 0.13
Nodes (14): build, children, footer, helperText, OnboardingStepFooter, OnboardingStepScaffold, onPrimary, onSkip (+6 more)

### Community 54 - "theme_picker_sheet.dart"
Cohesion: 0.13
Nodes (14): Color, build, color, icon, label, onTap, _options, selected (+6 more)

### Community 55 - "offline_status_capsule_test.dart"
Cohesion: 0.07
Nodes (27): Container, FadeTransition, Icon, InkWell, package:medico/screens/home_screen.dart, package:medico/widgets/offline_status_capsule.dart, SingleChildScrollView, SlideTransition (+19 more)

### Community 56 - "session_expiry_test.dart"
Cohesion: 0.06
Nodes (31): package:http/testing.dart, package:medico/screens/auth_gate.dart, _anonKey, _boot, calls, client, didRefresh, exp (+23 more)

### Community 57 - "VoidCallback"
Cohesion: 0.18
Nodes (10): aurora_buttons.dart, IconData, AuroraSelectField, build, icon, onTap, placeholder, subtitle (+2 more)

### Community 58 - "MaterialPageRoute"
Cohesion: 0.25
Nodes (8): _goSignUp, _resendConfirmation, _handleSubmit, _forwardToSignIn, _goSignIn, _goSignUp, MaterialPageRoute, main

### Community 60 - "package:flutter/material.dart"
Cohesion: 0.29
Nodes (6): BookingsTab, build, BrowseTab, build, package:flutter/material.dart, ../theme/aurora_tokens.dart

### Community 61 - "sign_up_screen_test.dart"
Cohesion: 0.17
Nodes (11): Checkbox, agreeToTerms, depth, didPop, didPush, didRemove, didReplace, main (+3 more)

### Community 62 - "arabic_formatting.dart"
Cohesion: 0.11
Nodes (18): buffer, CountedParts, digits, _easternArabicDigits, formatArabicClock12, hour12, hour24, _joinParts (+10 more)

### Community 63 - "sign_in_screen_test.dart"
Cohesion: 0.18
Nodes (10): AuthTextField, _AuthTextFieldState, depth, didPop, didPush, didRemove, didReplace, main (+2 more)

### Community 64 - "wait_estimate.dart"
Cohesion: 0.20
Nodes (9): arabic_formatting.dart, add, estimatedTurnTime, high, low, _roundToNearest5, total, totalWaitMinutes (+1 more)

### Community 65 - "auth_gate.dart"
Cohesion: 0.50
Nodes (3): auth_gate.dart, build, SplashScreen

### Community 67 - "onboarding_flow_screen.dart"
Cohesion: 0.06
Nodes (33): build, _completionStep, createState, _data, dispose, _enableNotifications, _finish, _goTo (+25 more)

### Community 68 - "onboarding_completion_screen.dart"
Cohesion: 0.08
Nodes (23): CustomPainter, dart:ui, _badgeScale, _Blob, _blobBlue, build, _buttonFade, _checkDraw (+15 more)

### Community 69 - "onboarding_year_picker_sheet.dart"
Cohesion: 0.05
Nodes (39): FixedExtentScrollController, _PreviewApp, build, _CityPickerSheet, _CityPickerSheetState, _CityRow, createState, current (+31 more)

### Community 70 - "onboarding_milestone_stepper.dart"
Cohesion: 0.07
Nodes (27): build, _column, _half, height, index, isActive, isDone, _labelGap (+19 more)

### Community 71 - "home_empty_state_card.dart"
Cohesion: 0.09
Nodes (23): _blobControllers, _blobDurations, build, controller, createState, _ctaInk, didChangeDependencies, dispose (+15 more)

### Community 72 - "connectivity_service.dart"
Cohesion: 0.06
Nodes (32): bool?, Duration, _apply, checkNow, _committedOnline, _confirm, _confirmDisconnect, _confirmReconnect (+24 more)

### Community 73 - "aurora_buttons.dart"
Cohesion: 0.11
Nodes (19): AuroraIconButton, AuroraPressable, _AuroraPressableState, AuroraPrimaryButton, AuroraSecondaryButton, AuroraSectionTitle, build, child (+11 more)

### Community 74 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.25
Nodes (7): package:flutter_test/flutter_test.dart, package:medico/models/onboarding_data.dart, package:medico/services/onboarding_sync_service.dart, main, service, userA, userB

### Community 75 - "Password Reset Web Page"
Cohesion: 0.22
Nodes (9): Aurora Sheet Design System, Password Policy: 8 Chars, No Composition Rule, _resetPasswordRedirect, _validateEmail, Password Reset Web Page, screens Element Map, showFatalError, showScreen (+1 more)

### Community 76 - "fake_connectivity.dart"
Cohesion: 0.11
Nodes (17): AndSettle, ConnectivityService, List, return, _changes, changeSilently, dispose, emit (+9 more)

### Community 77 - "welcome_screen_test.dart"
Cohesion: 0.29
Nodes (6): auth_test_support.dart, NavigatorState, package:medico/screens/sign_in_screen.dart, package:medico/screens/welcome_screen.dart, package:medico/theme/aurora_tokens.dart, main

### Community 78 - "firebase_options.dart"
Cohesion: 0.22
Nodes (8): android, DefaultFirebaseOptions, ios, macos, web, windows, package:firebase_core/firebase_core.dart, static const FirebaseOptions

### Community 79 - "inline_error_overflow_test.dart"
Cohesion: 0.29
Nodes (6): package:medico/screens/sign_up_screen.dart, package:medico/widgets/auth_surface.dart, budgetAndroid, main, signInSubmit, signUpSubmit

### Community 80 - "auth_gate.dart"
Cohesion: 0.06
Nodes (33): home_screen.dart, _attemptResolve, AuthGate, _AuthGateState, build, _cache, _confirmedRejectionCodes, _connectivitySub (+25 more)

### Community 81 - "static const"
Cohesion: 0.25
Nodes (7): forget, _onboardedPrefix, remember, SessionCache, _verifiedPrefix, package:shared_preferences/shared_preferences.dart, static const

### Community 82 - "dart:async"
Cohesion: 0.29
Nodes (6): dart:async, fake_connectivity.dart, package:connectivity_plus/connectivity_plus.dart, package:medico/services/connectivity_service.dart, main, record

### Community 83 - "NavigatorObserver"
Cohesion: 0.67
Nodes (3): NavigatorObserver, _RouteCounter, _RouteCounter

### Community 85 - "home_screen.dart"
Cohesion: 0.09
Nodes (22): bookings_tab.dart, browse_tab.dart, home_tab.dart, build, _connectivity, connectivityService, createState, didChangeAppLifecycleState (+14 more)

### Community 87 - "notification_service.dart"
Cohesion: 0.29
Nodes (6): dart:io, NotificationService, registerDeviceToken, requestPermission, package:firebase_messaging/firebase_messaging.dart, package:permission_handler/permission_handler.dart

### Community 89 - "_OnboardingCompletionScreenState"
Cohesion: 0.40
Nodes (5): OnboardingCompletionScreen, _OnboardingCompletionScreenState, OnboardingStep3Notifications, _OnboardingStep3NotificationsState, SingleTickerProviderStateMixin

### Community 90 - "_codeMessages"
Cohesion: 0.50
Nodes (4): _codeMessages, mapAuthError, ERROR_CODE_MESSAGES, mapUpdatePasswordError

### Community 92 - "ThemeMode"
Cohesion: 0.67
Nodes (3): ThemeController, ThemeMode, ValueNotifier

## Ambiguous Edges - Review These
- `One Screen Per File Rule` → `Graphify Skill Trigger`  [AMBIGUOUS]
  .claude/CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **1085 isolated node(s):** `connectivityService`, `_selectedSpecialtyKey`, `_refreshEpoch`, `_placeholderRefreshDelay`, `_phaseSub` (+1080 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `One Screen Per File Rule` and `Graphify Skill Trigger`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `AuthErrorInfo` connect `forgot_password_sheet.dart` to `sign_up_screen.dart`, `auth_error_mapper.dart`, `sign_in_screen.dart`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **Why does `_resetPasswordRedirect` connect `Password Reset Web Page` to `forgot_password_sheet.dart`?**
  _High betweenness centrality (0.003) - this node is a cross-community bridge._
- **Why does `Gender` connect `user_profile.dart` to `onboarding_gender_control.dart`, `profile_tab.dart`?**
  _High betweenness centrality (0.003) - this node is a cross-community bridge._
- **What connects `connectivityService`, `_selectedSpecialtyKey`, `_refreshEpoch` to the rest of the system?**
  _1085 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `auth_surface.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03389830508474576 - nodes in this community are weakly interconnected._
- **Should `sign_up_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05405405405405406 - nodes in this community are weakly interconnected._