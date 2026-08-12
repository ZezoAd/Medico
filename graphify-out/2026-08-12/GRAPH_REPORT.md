# Graph Report - medico  (2026-08-12)

## Corpus Check
- 58 files · ~18,892 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 528 nodes · 658 edges · 29 communities (23 shown, 6 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 23 edges (avg confidence: 0.81)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c086ecb9`
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
- sign_up_screen_test.dart
- medico pubspec.yaml package manifest
- manifest.json
- forgot_password_sheet.dart
- Linux top-level CMake build config
- otp_verification_screen.dart
- auth_error_banner.dart
- MainActivity.kt
- .claude/CLAUDE.md graphify trigger instructions
- RegisterPlugins
- Flutter DevTools configuration
- iOS LaunchImage asset instructions
- medico project README
- String?
- StatelessWidget
- initState
- user_profile.dart

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

## Communities (29 total, 6 thin omitted)

### Community 0 - "sign_in_page.dart"
Cohesion: 0.03
Nodes (62): _banner, _border, build, _buildBrand, _buildCard, _buildDivider, _buildFieldError, _buildForm (+54 more)

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
Cohesion: 0.09
Nodes (21): android, DefaultFirebaseOptions, ios, macos, web, windows, build, buildOverscrollIndicator (+13 more)

### Community 5 - "auth_error_mapper.dart"
Cohesion: 0.09
Nodes (22): dart:async, dart:io, home_screen.dart, _bootstrap, build, _destinationForSession, fetchCurrentProfile, ProfileService (+14 more)

### Community 6 - "sign_up_screen.dart"
Cohesion: 0.03
Nodes (58): double get, _agreedToPrivacy, _banner, _border, build, _buildBrand, _buildCard, _buildDivider (+50 more)

### Community 7 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 8 - "sign_up_screen_test.dart"
Cohesion: 0.08
Nodes (22): Checkbox, build, HomeScreen, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:medico/main.dart, package:medico/screens/sign_in_page.dart, package:medico/screens/sign_up_screen.dart (+14 more)

### Community 9 - "medico pubspec.yaml package manifest"
Cohesion: 0.18
Nodes (11): Dart analyzer configuration, firebase_core package, firebase_crashlytics package, firebase_messaging package, flutter_dotenv package, flutter_lints package, google_sign_in package, supabase package (+3 more)

### Community 10 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 11 - "forgot_password_sheet.dart"
Cohesion: 0.06
Nodes (33): auth_error_banner.dart, AuthErrorInfo?, _banner, _border, build, _cooldown, _cooldownSeconds, _cooldownTimer (+25 more)

### Community 12 - "Linux top-level CMake build config"
Cohesion: 0.60
Nodes (6): Linux top-level CMake build config, Linux flutter library CMake target, Linux runner executable CMake target, Windows top-level CMake build config, Windows flutter library CMake target, Windows runner executable CMake target

### Community 13 - "otp_verification_screen.dart"
Cohesion: 0.04
Nodes (44): _bannerRetry, _border, build, _buildBody, _buildBrand, _buildCard, _buildDigitRow, _buildForm (+36 more)

### Community 14 - "auth_error_banner.dart"
Cohesion: 0.06
Nodes (34): OtpVerificationScreen, _OtpVerificationScreenState, SignInPage, _SignInPageState, SignInScreen, SignUpScreen, _SignUpScreenState, _amber (+26 more)

### Community 16 - ".claude/CLAUDE.md graphify trigger instructions"
Cohesion: 1.00
Nodes (3): .claude/CLAUDE.md graphify trigger instructions, CLAUDE.md graphify usage rules, graphify knowledge graph tool

### Community 26 - "StatelessWidget"
Cohesion: 0.22
Nodes (9): MedicoApp, _GradientBackdrop, _SoftCircle, _GradientBackdrop, _SoftCircle, _GradientBackdrop, _SoftCircle, SplashScreen (+1 more)

### Community 27 - "initState"
Cohesion: 0.67
Nodes (3): initState, _handleSubmit, MaterialPageRoute

### Community 28 - "user_profile.dart"
Cohesion: 0.13
Nodes (14): bool get, doctor, fromMap, fromText, fullName, id, isDoctor, phone (+6 more)

## Knowledge Gaps
- **291 isolated node(s):** `_Role`, `initialErrorMessage`, `_teal`, `_ink`, `_muted` (+286 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FlutterWindow` connect `Win32Window` to `GeneratedPluginRegistrant.swift`?**
  _High betweenness centrality (0.028) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `MessageHandler` (e.g. with `Destroy` and `GetClientArea`) actually correct?**
  _`MessageHandler` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `Create` (e.g. with `Destroy` and `UpdateTheme`) actually correct?**
  _`Create` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `_Role`, `initialErrorMessage`, `_teal` to the rest of the system?**
  _291 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `sign_in_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.031746031746031744 - nodes in this community are weakly interconnected._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.06594071385359952 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.05087881591119334 - nodes in this community are weakly interconnected._