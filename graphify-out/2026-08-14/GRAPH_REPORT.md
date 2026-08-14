# Graph Report - medico  (2026-08-14)

## Corpus Check
- 60 files · ~23,239 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 572 nodes · 711 edges · 31 communities (25 shown, 6 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 23 edges (avg confidence: 0.81)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `2e74238f`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- sign_in_page.dart
- Win32Window
- GeneratedPluginRegistrant.swift
- my_application.cc
- main.dart
- auth_error_mapper.dart
- sign_up_screen.dart
- wWinMain
- package:flutter/material.dart
- medico pubspec.yaml package manifest
- manifest.json
- forgot_password_sheet.dart
- Linux top-level CMake build config
- otp_verification_screen.dart
- auth_error_banner.dart
- MainActivity.kt
- .claude/CLAUDE.md graphify trigger instructions
- State
- Flutter DevTools configuration
- iOS LaunchImage asset instructions
- medico project README
- String?
- RegisterPlugins
- MaterialPageRoute
- user_profile.dart
- splash_screen.dart
- StatelessWidget

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 22 edges
2. `MessageHandler` - 12 edges
3. `FlutterWindow` - 10 edges
4. `Create` - 10 edges
5. `WndProc` - 10 edges
6. `MessageHandler` - 9 edges
7. `medico pubspec.yaml package manifest` - 9 edges
8. `_MyApplication` - 7 edges
9. `OnCreate` - 7 edges
10. `WindowClassRegistrar` - 7 edges

## Surprising Connections (you probably didn't know these)
- `CLAUDE.md graphify usage rules` --semantically_similar_to--> `.claude/CLAUDE.md graphify trigger instructions`  [INFERRED] [semantically similar]
  CLAUDE.md → .claude/CLAUDE.md
- `Linux top-level CMake build config` --semantically_similar_to--> `Windows top-level CMake build config`  [INFERRED] [semantically similar]
  linux/CMakeLists.txt → windows/CMakeLists.txt
- `Linux flutter library CMake target` --semantically_similar_to--> `Windows flutter library CMake target`  [INFERRED] [semantically similar]
  linux/flutter/CMakeLists.txt → windows/flutter/CMakeLists.txt
- `Linux runner executable CMake target` --semantically_similar_to--> `Windows runner executable CMake target`  [INFERRED] [semantically similar]
  linux/runner/CMakeLists.txt → windows/runner/CMakeLists.txt
- `Flutter web index.html entrypoint` --conceptually_related_to--> `medico pubspec.yaml package manifest`  [INFERRED]
  web/index.html → pubspec.yaml

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Cross-platform CMake build configs (Linux & Windows)** — linux_cmakelists_linux_build_config, linux_flutter_cmakelists_flutter_library_target, linux_runner_cmakelists_runner_executable_target, windows_cmakelists_windows_build_config, windows_flutter_cmakelists_flutter_library_target, windows_runner_cmakelists_runner_executable_target [INFERRED 0.80]
- **Firebase service integration via pubspec dependencies** — concept_firebase_core, concept_firebase_messaging, concept_firebase_crashlytics [INFERRED 0.85]
- **graphify skill trigger configuration across CLAUDE.md files** — claude_claude_md_graphify_trigger, claude_md_graphify_rules, concept_graphify [EXTRACTED 1.00]

## Communities (31 total, 6 thin omitted)

### Community 0 - "sign_in_page.dart"
Cohesion: 0.03
Nodes (67): _banner, _border, build, _buildBrand, _buildCard, _buildDivider, _buildFieldError, _buildForm (+59 more)

### Community 1 - "Win32Window"
Cohesion: 0.07
Nodes (51): Point, RECT, Size, unique_ptr, DartProject, HWND, LPARAM, LRESULT (+43 more)

### Community 2 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (33): Any, app_links, Cocoa, firebase_core, firebase_crashlytics, firebase_messaging, Flutter, FlutterAppDelegate (+25 more)

### Community 3 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 4 - "main.dart"
Cohesion: 0.07
Nodes (26): android, DefaultFirebaseOptions, ios, macos, web, windows, build, buildOverscrollIndicator (+18 more)

### Community 5 - "auth_error_mapper.dart"
Cohesion: 0.06
Nodes (30): AuthErrorSeverity, accountAlreadyExistsMessage, any, AuthErrorInfo, code, _codeMessages, emailNotConfirmedMessage, error (+22 more)

### Community 6 - "sign_up_screen.dart"
Cohesion: 0.03
Nodes (61): AuthErrorInfo?, double get, _agreedToPrivacy, _banner, _border, build, _buildBrand, _buildCard (+53 more)

### Community 7 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 8 - "package:flutter/material.dart"
Cohesion: 0.08
Nodes (25): Checkbox, build, HomeScreen, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:medico/main.dart, package:medico/screens/sign_in_page.dart, package:medico/screens/sign_up_screen.dart (+17 more)

### Community 9 - "medico pubspec.yaml package manifest"
Cohesion: 0.18
Nodes (11): Dart analyzer configuration, firebase_core package, firebase_crashlytics package, firebase_messaging package, flutter_dotenv package, flutter_lints package, google_sign_in package, supabase package (+3 more)

### Community 10 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 11 - "forgot_password_sheet.dart"
Cohesion: 0.06
Nodes (31): auth_error_banner.dart, _banner, _border, build, _cooldown, _cooldownSeconds, _cooldownTimer, createState (+23 more)

### Community 12 - "Linux top-level CMake build config"
Cohesion: 0.60
Nodes (6): Linux top-level CMake build config, Linux flutter library CMake target, Linux runner executable CMake target, Windows top-level CMake build config, Windows flutter library CMake target, Windows runner executable CMake target

### Community 13 - "otp_verification_screen.dart"
Cohesion: 0.04
Nodes (52): DateTime, _bannerRetry, _border, build, _buildBody, _buildBrand, _buildCard, _buildForm (+44 more)

### Community 14 - "auth_error_banner.dart"
Cohesion: 0.08
Nodes (25): _amber, AuthErrorBanner, _AuthErrorBannerState, AuthErrorSeverity, _autoDismissDelay, _autoDismissTimer, build, createState (+17 more)

### Community 16 - ".claude/CLAUDE.md graphify trigger instructions"
Cohesion: 1.00
Nodes (3): .claude/CLAUDE.md graphify trigger instructions, CLAUDE.md graphify usage rules, graphify knowledge graph tool

### Community 17 - "State"
Cohesion: 0.22
Nodes (10): OtpVerificationScreen, _OtpVerificationScreenState, SignInPage, _SignInPageState, SignInScreen, SignUpScreen, _SignUpScreenState, sign_in_page.dart (+2 more)

### Community 27 - "MaterialPageRoute"
Cohesion: 0.50
Nodes (4): initState, _resendConfirmation, _handleSubmit, MaterialPageRoute

### Community 28 - "user_profile.dart"
Cohesion: 0.12
Nodes (16): bool get, doctor, fromMap, fromText, fullName, id, isDoctor, phone (+8 more)

### Community 29 - "splash_screen.dart"
Cohesion: 0.20
Nodes (9): dart:async, dart:io, home_screen.dart, _bootstrap, build, _destinationForSession, ../services/profile_service.dart, sign_in_screen.dart (+1 more)

### Community 30 - "StatelessWidget"
Cohesion: 0.22
Nodes (9): MedicoApp, _GradientBackdrop, _SoftCircle, _GradientBackdrop, _SoftCircle, _GradientBackdrop, _SoftCircle, SplashScreen (+1 more)

## Knowledge Gaps
- **331 isolated node(s):** `UserRole`, `UserProfile`, `doctor`, `text`, `id` (+326 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FlutterWindow` connect `Win32Window` to `GeneratedPluginRegistrant.swift`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `MessageHandler` (e.g. with `Destroy` and `GetClientArea`) actually correct?**
  _`MessageHandler` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `Create` (e.g. with `Destroy` and `UpdateTheme`) actually correct?**
  _`Create` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `UserRole`, `UserProfile`, `doctor` to the rest of the system?**
  _331 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `sign_in_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.029411764705882353 - nodes in this community are weakly interconnected._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.06594071385359952 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.05087881591119334 - nodes in this community are weakly interconnected._