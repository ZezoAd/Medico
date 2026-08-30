# Graph Report - medico  (2026-08-29)

## Corpus Check
- 94 files · ~72,255 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1364 nodes · 1812 edges · 74 communities (66 shown, 8 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `2763b70e`
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
- home_featured_doctors.dart
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
- ../theme/aurora_tokens.dart
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
- package:flutter_test/flutter_test.dart
- sign_in_screen_test.dart
- notification_service.dart
- Recovery Token Verification
- ../models/onboarding_data.dart
- package:supabase_flutter/supabase_flutter.dart
- home_featured_doctors_test.dart
- sign_in_screen.dart
- onboarding_step3_notifications.dart
- queue_status_card_preview.dart
- home_empty_state_card_preview.dart
- onboarding_step1_basics.dart
- theme_test.dart
- onboarding_step2_city.dart
- onboarding_step_scaffold.dart
- State
- _OnboardingCompletionScreenState
- Password Reset Web Page
- VoidCallback
- MaterialPageRoute
- One Screen Per File Rule
- global_offline_strip.dart
- package:flutter/material.dart
- arabic_formatting.dart
- firebase_options.dart
- wait_estimate.dart
- auth_gate.dart
- AuroraPaletteContext
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
6. `AuroraPalette` - 5 edges
7. `AuthTextField` - 5 edges
8. `Password Reset Web Page` - 5 edges
9. `Recovery Token Verification` - 5 edges
10. `_OnboardingCompletionScreenState` - 4 edges

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

## Communities (74 total, 8 thin omitted)

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
Nodes (30): accountAlreadyExistsMessage, any, code, _codeMessages, emailNotConfirmedMessage, error, genericAuthErrorMessage, isEmailNotConfirmedError (+22 more)

### Community 6 - "forgot_password_sheet.dart"
Cohesion: 0.08
Nodes (24): auth_error_banner.dart, AuthErrorInfo, _banner, build, _cooldown, _cooldownSeconds, _cooldownTimer, createState (+16 more)

### Community 7 - "profile_tab_test.dart"
Cohesion: 0.18
Nodes (10): package:flutter/rendering.dart, package:medico/screens/home_tab.dart, package:medico/screens/profile_tab.dart, RenderParagraph, _host, isSignedIn, main, _narrow (+2 more)

### Community 8 - "main.dart"
Cohesion: 0.06
Nodes (31): Color, build, buildOverscrollIndicator, init, initializeApp, load, main, MedicoApp (+23 more)

### Community 9 - "home_featured_doctors.dart"
Cohesion: 0.06
Nodes (35): @immutable, double?, clinicName, Doctor, id, name, photoUrl, rating (+27 more)

### Community 10 - "auth_error_banner.dart"
Cohesion: 0.05
Nodes (42): aurora_tokens.dart, dart:async, init, instance, _key, load, save, service (+34 more)

### Community 11 - "user_profile.dart"
Cohesion: 0.05
Nodes (36): bool get, int?, arabicLabel, birthYear, city, copyWith, fromText, Gender (+28 more)

### Community 12 - "StatelessWidget"
Cohesion: 0.08
Nodes (25): AuthBackButton, AuthBackdrop, AuthCollapsible, AuthFieldLabel, AuthFooterPrompt, AuthGoogleButton, AuthHero, AuthInlineError (+17 more)

### Community 13 - "aurora_tokens.dart"
Cohesion: 0.02
Nodes (95): AuroraPalette get, BoxBorder?, accentOnTonal, accentOnTonalDark, aurora, AuroraColors, AuroraFontSize, AuroraGradients (+87 more)

### Community 14 - "onboarding_sync_service.dart"
Cohesion: 0.11
Nodes (17): dart:convert, clearPending, clearProgress, data, hasPending, _key, loadProgress, _maxStep (+9 more)

### Community 15 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 16 - "queue_status_card.dart"
Cohesion: 0.05
Nodes (43): avgConsultMinutes, _blobControllers, _blobDurations, build, card, connectionStatus, controller, createState (+35 more)

### Community 17 - "onboarding_v6.jsx"
Cohesion: 0.07
Nodes (21): bodyFont, C, CURRENT_YEAR, displayFont, E, F, GOVERNORATES, InlineSkipButton() (+13 more)

### Community 18 - "onboarding_city_picker_sheet.dart"
Cohesion: 0.06
Nodes (33): build, _CityPickerSheet, _CityPickerSheetState, _CityRow, createState, current, dispose, kGovernorates (+25 more)

### Community 20 - "../theme/aurora_tokens.dart"
Cohesion: 0.50
Nodes (3): BrowseTab, build, ../theme/aurora_tokens.dart

### Community 21 - "profile_tab.dart"
Cohesion: 0.06
Nodes (31): build, busy, contact, createState, email, enabled, _fallbackContact, _fallbackName (+23 more)

### Community 26 - "onboarding_gender_control.dart"
Cohesion: 0.15
Nodes (13): build, _canSlide, createState, didUpdateWidget, initState, OnboardingGenderControl, _OnboardingGenderControlState, onChanged (+5 more)

### Community 30 - "home_specialty_chips.dart"
Cohesion: 0.05
Nodes (41): FaIconData, _bellSize, build, createState, height, HomeTab, _HomeTabState, _HomeTopBar (+33 more)

### Community 33 - "home_specialty_chips_test.dart"
Cohesion: 0.12
Nodes (15): package:medico/widgets/home_empty_state_card.dart, chipLabel, chipRow, descendant, dragUntilVisible, ensureVisible, labels, main (+7 more)

### Community 34 - "welcome_screen.dart"
Cohesion: 0.09
Nodes (21): _BrandMark, _BrandPanel, build, createState, _CrossBar, _forwarding, height, initialErrorMessage (+13 more)

### Community 35 - "Auth Fallback Chain"
Cohesion: 0.28
Nodes (9): Google G Logo Mark, Auth Fallback Chain, OtpVerificationScreen, _OtpVerificationScreenState, flutter_svg Dependency, google_sign_in Dependency, medico Flutter Package, pinput Dependency (+1 more)

### Community 36 - "auth_test_support.dart"
Cohesion: 0.07
Nodes (27): arabicIndic, decorated, dpr, expectFieldClearOfKeyboard, expectNoArabicIndicDigits, false, heroGradientOf, inset (+19 more)

### Community 37 - "otp_verification_screen_test.dart"
Cohesion: 0.15
Nodes (12): Directionality, AuthPrimaryButton, package:medico/screens/otp_verification_screen.dart, package:pinput/pinput.dart, Pinput, Size, _email, keyboardInset (+4 more)

### Community 38 - "sign_up_screen_test.dart"
Cohesion: 0.13
Nodes (14): Checkbox, NavigatorObserver, _RouteCounter, agreeToTerms, depth, didPop, didPush, didRemove (+6 more)

### Community 39 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.22
Nodes (8): package:flutter_test/flutter_test.dart, package:medico/models/onboarding_data.dart, package:medico/services/onboarding_sync_service.dart, package:shared_preferences/shared_preferences.dart, main, service, userA, userB

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

### Community 45 - "home_featured_doctors_test.dart"
Cohesion: 0.14
Nodes (13): DoctorCard, package:medico/models/doctor.dart, package:medico/widgets/home_featured_doctors.dart, main, mediumPhone, mode, pumpAndSettle, pumpCard (+5 more)

### Community 46 - "sign_in_screen.dart"
Cohesion: 0.06
Nodes (35): _banner, _bannerAction, _bannerActionLabel, build, _buildBanner, _clearBanner, createState, _credentialsError (+27 more)

### Community 47 - "onboarding_step3_notifications.dart"
Cohesion: 0.10
Nodes (19): Animation, AnimationController, class, build, _Chip, _ChipRow, _chips, createState (+11 more)

### Community 48 - "queue_status_card_preview.dart"
Cohesion: 0.15
Nodes (12): DateTime, build, createState, label, main, _recordedAt, _Scenario, _setScenario (+4 more)

### Community 49 - "home_empty_state_card_preview.dart"
Cohesion: 0.15
Nodes (12): AppThemeVariant, build, child, createState, _Forced, label, main, _Mode (+4 more)

### Community 50 - "onboarding_step1_basics.dart"
Cohesion: 0.18
Nodes (10): build, data, OnboardingStep1Basics, onChanged, onContinue, onSkip, _pickYear, onboarding_gender_control.dart (+2 more)

### Community 51 - "theme_test.dart"
Cohesion: 0.15
Nodes (12): Brightness, DecoratedBox, package:medico/services/theme_service.dart, package:medico/theme/app_theme.dart, package:medico/widgets/home_specialty_chips.dart, _host, inner, main (+4 more)

### Community 52 - "onboarding_step2_city.dart"
Cohesion: 0.20
Nodes (9): build, data, OnboardingStep2City, onChanged, onContinue, _pickCity, onboarding_city_picker_sheet.dart, onboarding_step_scaffold.dart (+1 more)

### Community 53 - "onboarding_step_scaffold.dart"
Cohesion: 0.13
Nodes (14): build, children, footer, helperText, OnboardingStepFooter, OnboardingStepScaffold, onPrimary, onSkip (+6 more)

### Community 54 - "State"
Cohesion: 0.15
Nodes (18): _PreviewApp, _PreviewAppState, _PreviewApp, _PreviewAppState, SignInScreen, _SignInScreenState, WelcomeScreen, _WelcomeScreenState (+10 more)

### Community 55 - "_OnboardingCompletionScreenState"
Cohesion: 0.40
Nodes (5): OnboardingCompletionScreen, _OnboardingCompletionScreenState, OnboardingStep3Notifications, _OnboardingStep3NotificationsState, SingleTickerProviderStateMixin

### Community 56 - "Password Reset Web Page"
Cohesion: 0.22
Nodes (9): Aurora Sheet Design System, Password Policy: 8 Chars, No Composition Rule, _resetPasswordRedirect, _validateEmail, Password Reset Web Page, screens Element Map, showFatalError, showScreen (+1 more)

### Community 57 - "VoidCallback"
Cohesion: 0.18
Nodes (10): aurora_buttons.dart, IconData, AuroraSelectField, build, icon, onTap, placeholder, subtitle (+2 more)

### Community 58 - "MaterialPageRoute"
Cohesion: 0.25
Nodes (8): _goSignUp, _resendConfirmation, _handleSubmit, _forwardToSignIn, _goSignIn, _goSignUp, MaterialPageRoute, main

### Community 60 - "global_offline_strip.dart"
Cohesion: 0.40
Nodes (4): build, GlobalOfflineStrip, _OfflineStripBody, visible

### Community 61 - "package:flutter/material.dart"
Cohesion: 0.50
Nodes (3): BookingsTab, build, package:flutter/material.dart

### Community 62 - "arabic_formatting.dart"
Cohesion: 0.11
Nodes (18): buffer, CountedParts, digits, _easternArabicDigits, formatArabicClock12, hour12, hour24, _joinParts (+10 more)

### Community 63 - "firebase_options.dart"
Cohesion: 0.22
Nodes (8): android, DefaultFirebaseOptions, ios, macos, web, windows, package:firebase_core/firebase_core.dart, static const FirebaseOptions

### Community 64 - "wait_estimate.dart"
Cohesion: 0.20
Nodes (9): arabic_formatting.dart, add, estimatedTurnTime, high, low, _roundToNearest5, total, totalWaitMinutes (+1 more)

### Community 65 - "auth_gate.dart"
Cohesion: 0.50
Nodes (3): auth_gate.dart, build, SplashScreen

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
Cohesion: 0.10
Nodes (20): _blobControllers, _blobDurations, build, controller, createState, _ctaInk, didChangeDependencies, dispose (+12 more)

### Community 73 - "aurora_buttons.dart"
Cohesion: 0.11
Nodes (19): AuroraIconButton, AuroraPressable, _AuroraPressableState, AuroraPrimaryButton, AuroraSecondaryButton, AuroraSectionTitle, build, child (+11 more)

### Community 80 - "auth_gate.dart"
Cohesion: 0.07
Nodes (28): AuthGate, _AuthGateState, build, _connectivitySub, createState, dispose, _drainPendingOnboarding, _failClosed (+20 more)

### Community 85 - "home_screen.dart"
Cohesion: 0.12
Nodes (16): bookings_tab.dart, browse_tab.dart, home_tab.dart, build, createState, _email, HomeScreen, _HomeScreenState (+8 more)

## Ambiguous Edges - Review These
- `One Screen Per File Rule` → `Graphify Skill Trigger`  [AMBIGUOUS]
  .claude/CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **890 isolated node(s):** `AR`, `AURORA`, `C`, `S`, `R` (+885 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `One Screen Per File Rule` and `Graphify Skill Trigger`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `AuroraPalette` connect `home_featured_doctors.dart` to `aurora_tokens.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Why does `_resetPasswordRedirect` connect `Password Reset Web Page` to `forgot_password_sheet.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `AR`, `AURORA`, `C` to the rest of the system?**
  _890 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `auth_surface.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03389830508474576 - nodes in this community are weakly interconnected._
- **Should `sign_up_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05405405405405406 - nodes in this community are weakly interconnected._
- **Should `otp_verification_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05128205128205128 - nodes in this community are weakly interconnected._