# Graph Report - medico  (2026-08-25)

## Corpus Check
- 83 files · ~49,387 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1108 nodes · 1431 edges · 62 communities (52 shown, 10 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 20 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f18a1613`
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
- profile_tab_test.dart
- main.dart
- onboarding_step_scaffold.dart
- auth_error_banner.dart
- user_profile.dart
- StatelessWidget
- aurora_tokens.dart
- SignInPage
- manifest.json
- queue_status_card.dart
- onboarding_v6.jsx
- onboarding_city_picker_sheet.dart
- MainActivity.kt
- One Screen Per File Rule
- profile_tab.dart
- Dart analyzer configuration
- onboarding_step1_basics.dart
- Flutter DevTools configuration
- iOS LaunchImage asset instructions
- _PreviewApp
- medico project README
- Flutter web index.html entrypoint
- home_empty_state_card_preview.dart
- sign_in_page_test.dart
- Auth Fallback Chain
- global_offline_strip.dart
- String?
- sign_up_screen_test.dart
- onboarding_progress_test.dart
- inline_error_overflow_test.dart
- notification_service.dart
- signup_verified Gate
- onboarding_preview.dart
- package:supabase_flutter/supabase_flutter.dart
- package:flutter_test/flutter_test.dart
- SignUpScreen
- AuthErrorInfo?
- arabic_formatting.dart
- auth_gate.dart
- wait_estimate.dart
- _resendConfirmation
- onboarding_flow_screen.dart
- onboarding_completion_screen.dart
- onboarding_year_picker_sheet.dart
- home_empty_state_card.dart
- ../theme/aurora_tokens.dart
- aurora_buttons.dart
- auth_gate.dart
- onboarding_sync_service.dart
- package:flutter/material.dart
- home_screen.dart

## God Nodes (most connected - your core abstractions)
1. `usePress()` - 7 edges
2. `Gender` - 5 edges
3. `OnboardingData` - 5 edges
4. `AppDelegate` - 5 edges
5. `signup_verified Gate` - 5 edges
6. `Password Reset Web Page` - 5 edges
7. `Recovery Token Verification` - 5 edges
8. `SignInPage` - 4 edges
9. `AuthErrorInfo` - 4 edges
10. `_HomeEmptyStateCardState` - 4 edges

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

## Communities (62 total, 10 thin omitted)

### Community 0 - "sign_in_page.dart"
Cohesion: 0.04
Nodes (52): double get, _banner, build, _buildBrand, _buildCard, _buildDivider, _buildFieldError, _buildForm (+44 more)

### Community 1 - "ConnectivityArchitecture.jsx"
Cohesion: 0.29
Nodes (4): AR, AURORA, clock(), ConnectivityArchitecture()

### Community 2 - "sign_up_screen.dart"
Cohesion: 0.04
Nodes (52): _agreedToPrivacy, _banner, build, _buildAuthTabs, _buildBrand, _buildCard, _buildDivider, _buildFieldGroup (+44 more)

### Community 3 - "otp_verification_screen.dart"
Cohesion: 0.04
Nodes (45): _bannerRetry, build, _buildBody, _buildBrand, _buildCard, _buildForm, _buildPasswordUnchangedNote, _buildPinInput (+37 more)

### Community 4 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (33): Any, app_links, Cocoa, connectivity_plus, firebase_core, firebase_crashlytics, firebase_messaging, Flutter (+25 more)

### Community 5 - "auth_error_mapper.dart"
Cohesion: 0.06
Nodes (31): AuthErrorSeverity, accountAlreadyExistsMessage, any, code, _codeMessages, emailNotConfirmedMessage, error, genericAuthErrorMessage (+23 more)

### Community 6 - "forgot_password_sheet.dart"
Cohesion: 0.06
Nodes (34): auth_error_banner.dart, Aurora Sheet Design System, Password Policy: 8 Chars, No Composition Rule, _GradientBackdrop, AuthErrorInfo, _banner, build, _cooldown (+26 more)

### Community 7 - "profile_tab_test.dart"
Cohesion: 0.17
Nodes (11): package:flutter/rendering.dart, package:medico/screens/home_tab.dart, package:medico/screens/profile_tab.dart, package:medico/theme/aurora_tokens.dart, RenderParagraph, _host, isSignedIn, main (+3 more)

### Community 8 - "main.dart"
Cohesion: 0.09
Nodes (21): android, DefaultFirebaseOptions, ios, macos, web, windows, build, buildOverscrollIndicator (+13 more)

### Community 9 - "onboarding_step_scaffold.dart"
Cohesion: 0.13
Nodes (14): build, children, footer, helperText, OnboardingStepFooter, OnboardingStepScaffold, onPrimary, onSkip (+6 more)

### Community 10 - "auth_error_banner.dart"
Cohesion: 0.09
Nodes (23): dart:async, AuthErrorBanner, _AuthErrorBannerState, AuthErrorSeverity, autoDismiss, _autoDismissDelay, _autoDismissTimer, build (+15 more)

### Community 11 - "user_profile.dart"
Cohesion: 0.05
Nodes (36): bool get, int?, arabicLabel, birthYear, city, copyWith, fromText, Gender (+28 more)

### Community 12 - "StatelessWidget"
Cohesion: 0.12
Nodes (17): _SoftCircle, _GradientBackdrop, _SoftCircle, _GradientBackdrop, _SoftCircle, _BadgeShell, _CardContent, _ConnectionBadge (+9 more)

### Community 13 - "aurora_tokens.dart"
Cohesion: 0.03
Nodes (64): aurora, AuroraColors, AuroraFontSize, AuroraGradients, AuroraMotion, AuroraRadius, AuroraShadows, AuroraSpacing (+56 more)

### Community 14 - "SignInPage"
Cohesion: 0.40
Nodes (4): SignInPage, _SignInPageState, SignInScreen, sign_in_page.dart

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
Cohesion: 0.06
Nodes (37): DateTime, build, createState, label, main, _PreviewApp, _PreviewAppState, _recordedAt (+29 more)

### Community 21 - "profile_tab.dart"
Cohesion: 0.07
Nodes (29): build, busy, contact, createState, email, enabled, _fallbackContact, _fallbackName (+21 more)

### Community 26 - "onboarding_step1_basics.dart"
Cohesion: 0.06
Nodes (36): build, _canSlide, createState, didUpdateWidget, initState, OnboardingGenderControl, _OnboardingGenderControlState, onChanged (+28 more)

### Community 33 - "home_empty_state_card_preview.dart"
Cohesion: 0.15
Nodes (13): Brightness, brightness, build, child, createState, _Forced, label, main (+5 more)

### Community 34 - "sign_in_page_test.dart"
Cohesion: 0.17
Nodes (11): AuthTabSwitcher, package:medico/widgets/auth_tab_switcher.dart, iphoneSe, main, pixel8Pro, pumpAndSettle, pumpAt, pumpWidget (+3 more)

### Community 35 - "Auth Fallback Chain"
Cohesion: 0.28
Nodes (9): Google G Logo Mark, Auth Fallback Chain, OtpVerificationScreen, _OtpVerificationScreenState, flutter_svg Dependency, google_sign_in Dependency, medico Flutter Package, pinput Dependency (+1 more)

### Community 36 - "global_offline_strip.dart"
Cohesion: 0.40
Nodes (4): build, GlobalOfflineStrip, _OfflineStripBody, visible

### Community 37 - "String?"
Cohesion: 0.18
Nodes (10): aurora_buttons.dart, IconData, AuroraSelectField, build, icon, onTap, placeholder, subtitle (+2 more)

### Community 38 - "sign_up_screen_test.dart"
Cohesion: 0.20
Nodes (9): Checkbox, budgetAndroid, largePhone, main, modernPhone, pumpAndSettle, pumpAt, pumpWidget (+1 more)

### Community 39 - "onboarding_progress_test.dart"
Cohesion: 0.25
Nodes (7): package:medico/models/onboarding_data.dart, package:medico/services/onboarding_sync_service.dart, package:shared_preferences/shared_preferences.dart, main, service, userA, userB

### Community 40 - "inline_error_overflow_test.dart"
Cohesion: 0.25
Nodes (7): package:medico/screens/sign_in_page.dart, package:medico/screens/sign_up_screen.dart, budgetAndroid, main, signInSubmit, signUpSubmit, sizeTo

### Community 41 - "notification_service.dart"
Cohesion: 0.29
Nodes (6): dart:io, NotificationService, registerDeviceToken, requestPermission, package:firebase_messaging/firebase_messaging.dart, package:permission_handler/permission_handler.dart

### Community 42 - "signup_verified Gate"
Cohesion: 0.40
Nodes (6): signup_verified Gate, signupVerified, OtpPurpose, markSignupVerified, Recovery Token Verification, JS-Execution Scanner Defense

### Community 43 - "onboarding_preview.dart"
Cohesion: 0.33
Nodes (5): build, main, _PreviewApp, package:flutter/foundation.dart, ../screens/onboarding_flow_screen.dart

### Community 44 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.40
Nodes (4): fetchCurrentProfile, ProfileService, ../models/user_profile.dart, package:supabase_flutter/supabase_flutter.dart

### Community 45 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.50
Nodes (3): package:flutter_test/flutter_test.dart, package:medico/main.dart, main

### Community 62 - "arabic_formatting.dart"
Cohesion: 0.11
Nodes (18): buffer, CountedParts, digits, _easternArabicDigits, formatArabicClock12, hour12, hour24, _joinParts (+10 more)

### Community 63 - "auth_gate.dart"
Cohesion: 0.50
Nodes (3): auth_gate.dart, build, SplashScreen

### Community 64 - "wait_estimate.dart"
Cohesion: 0.20
Nodes (9): arabic_formatting.dart, add, estimatedTurnTime, high, low, _roundToNearest5, total, totalWaitMinutes (+1 more)

### Community 66 - "_resendConfirmation"
Cohesion: 0.50
Nodes (4): _buildAuthTabs, _resendConfirmation, _handleSubmit, MaterialPageRoute

### Community 67 - "onboarding_flow_screen.dart"
Cohesion: 0.06
Nodes (33): home_screen.dart, build, _completionStep, createState, _data, dispose, _enableNotifications, _finish (+25 more)

### Community 68 - "onboarding_completion_screen.dart"
Cohesion: 0.04
Nodes (47): Animation, AnimationController, class, CustomPainter, dart:ui, _badgeScale, _Blob, _blobBlue (+39 more)

### Community 69 - "onboarding_year_picker_sheet.dart"
Cohesion: 0.10
Nodes (21): FixedExtentScrollController, build, _controller, createState, dispose, _firstYear, initial, initState (+13 more)

### Community 71 - "home_empty_state_card.dart"
Cohesion: 0.06
Nodes (32): Color, active, _activeInk, build, label, labels, onSelected, onTap (+24 more)

### Community 72 - "../theme/aurora_tokens.dart"
Cohesion: 0.05
Nodes (40): BookingsTab, build, _bellSize, build, createState, height, HomeTab, _HomeTabState (+32 more)

### Community 73 - "aurora_buttons.dart"
Cohesion: 0.11
Nodes (19): AuroraIconButton, AuroraPressable, _AuroraPressableState, AuroraPrimaryButton, AuroraSecondaryButton, AuroraSectionTitle, build, child (+11 more)

### Community 80 - "auth_gate.dart"
Cohesion: 0.07
Nodes (29): AuthGate, _AuthGateState, build, _connectivitySub, createState, dispose, _drainPendingOnboarding, _failClosed (+21 more)

### Community 81 - "onboarding_sync_service.dart"
Cohesion: 0.11
Nodes (17): dart:convert, clearPending, clearProgress, data, hasPending, _key, loadProgress, _maxStep (+9 more)

### Community 83 - "package:flutter/material.dart"
Cohesion: 0.50
Nodes (3): BrowseTab, build, package:flutter/material.dart

### Community 85 - "home_screen.dart"
Cohesion: 0.12
Nodes (17): bookings_tab.dart, browse_tab.dart, home_tab.dart, build, createState, _email, HomeScreen, _HomeScreenState (+9 more)

## Ambiguous Edges - Review These
- `One Screen Per File Rule` → `Graphify Skill Trigger`  [AMBIGUOUS]
  .claude/CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **719 isolated node(s):** `_Mode`, `label`, `brightness`, `child`, `main` (+714 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `One Screen Per File Rule` and `Graphify Skill Trigger`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `_OtpVerificationScreenState` connect `Auth Fallback Chain` to `onboarding_city_picker_sheet.dart`, `otp_verification_screen.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `_Mode`, `label`, `brightness` to the rest of the system?**
  _719 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `sign_in_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03773584905660377 - nodes in this community are weakly interconnected._
- **Should `sign_up_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03773584905660377 - nodes in this community are weakly interconnected._
- **Should `otp_verification_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.043478260869565216 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.05087881591119334 - nodes in this community are weakly interconnected._