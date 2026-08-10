# Graph Report - .  (2026-08-10)

## Corpus Check
- Corpus is ~9,810 words - fits in a single context window. You may not need a graph.

## Summary
- 296 nodes · 367 edges · 25 communities (19 shown, 6 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 23 edges (avg confidence: 0.81)
- Token cost: 55,000 input · 5,582 output

## Community Hubs (Navigation)
- Sign-In Page UI
- Windows Win32 Window
- iOS/macOS App Bootstrap
- Linux App Bootstrap
- App Init & Firebase Config
- Windows Flutter Window
- Apple AppDelegate Lifecycle
- Windows Runner Utils
- Widget Tests
- Package Dependencies & Config
- Web App Manifest
- Sign-In Screen State
- CMake Build Targets
- Sign-In Decorative Widgets
- Windows Plugin Registrant
- Android MainActivity
- graphify CLAUDE.md Config
- Google Glyph Painter
- DevTools Config
- iOS Launch Image Docs
- Project README

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

## Communities (25 total, 6 thin omitted)

### Community 0 - "Sign-In Page UI"
Cohesion: 0.03
Nodes (58): bool get, double get, _blue, _border, build, _buildBrand, _buildCard, _buildDivider (+50 more)

### Community 1 - "Windows Win32 Window"
Cohesion: 0.10
Nodes (36): Point, RECT, Size, OnCreate, HWND, LPARAM, LRESULT, UINT (+28 more)

### Community 2 - "iOS/macOS App Bootstrap"
Cohesion: 0.07
Nodes (23): app_links, Cocoa, firebase_core, firebase_crashlytics, firebase_messaging, Flutter, FlutterMacOS, FlutterPluginRegistry (+15 more)

### Community 3 - "Linux App Bootstrap"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 4 - "App Init & Firebase Config"
Cohesion: 0.10
Nodes (19): android, DefaultFirebaseOptions, ios, macos, web, windows, build, initializeApp (+11 more)

### Community 5 - "Windows Flutter Window"
Cohesion: 0.13
Nodes (15): unique_ptr, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow (+7 more)

### Community 6 - "Apple AppDelegate Lifecycle"
Cohesion: 0.16
Nodes (10): Any, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, AppDelegate, Bool, AppDelegate, Bool (+2 more)

### Community 7 - "Windows Runner Utils"
Cohesion: 0.22
Nodes (9): _In_, _In_opt_, string, vector, wWinMain(), wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 8 - "Widget Tests"
Cohesion: 0.17
Nodes (11): package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:medico/main.dart, package:medico/screens/sign_in_page.dart, iphoneSe, main, pixel8Pro, pumpAndSettle (+3 more)

### Community 9 - "Package Dependencies & Config"
Cohesion: 0.18
Nodes (11): Dart analyzer configuration, firebase_core package, firebase_crashlytics package, firebase_messaging package, flutter_dotenv package, flutter_lints package, google_sign_in package, supabase package (+3 more)

### Community 10 - "Web App Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 11 - "Sign-In Screen State"
Cohesion: 0.29
Nodes (6): SignInPage, _SignInPageState, SignInScreen, sign_in_page.dart, State, StatefulWidget

### Community 12 - "CMake Build Targets"
Cohesion: 0.60
Nodes (6): Linux top-level CMake build config, Linux flutter library CMake target, Linux runner executable CMake target, Windows top-level CMake build config, Windows flutter library CMake target, Windows runner executable CMake target

### Community 13 - "Sign-In Decorative Widgets"
Cohesion: 0.40
Nodes (5): MedicoApp, _GoogleGlyph, _GradientBackdrop, _SoftCircle, StatelessWidget

### Community 16 - "graphify CLAUDE.md Config"
Cohesion: 1.00
Nodes (3): .claude/CLAUDE.md graphify trigger instructions, CLAUDE.md graphify usage rules, graphify knowledge graph tool

## Knowledge Gaps
- **112 isolated node(s):** `DefaultFirebaseOptions`, `web`, `android`, `ios`, `macos` (+107 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FlutterWindow` connect `Windows Flutter Window` to `Windows Win32 Window`, `iOS/macOS App Bootstrap`, `Windows Runner Utils`?**
  _High betweenness centrality (0.088) - this node is a cross-community bridge._
- **Why does `Win32Window` connect `Windows Win32 Window` to `Windows Flutter Window`, `Windows Runner Utils`?**
  _High betweenness centrality (0.062) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `MessageHandler` (e.g. with `Destroy` and `GetClientArea`) actually correct?**
  _`MessageHandler` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `Create` (e.g. with `Destroy` and `UpdateTheme`) actually correct?**
  _`Create` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `WndProc` (e.g. with `GetThisFromHandle` and `MessageHandler`) actually correct?**
  _`WndProc` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `DefaultFirebaseOptions`, `web`, `android` to the rest of the system?**
  _112 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Sign-In Page UI` be split into smaller, more focused modules?**
  _Cohesion score 0.03389830508474576 - nodes in this community are weakly interconnected._