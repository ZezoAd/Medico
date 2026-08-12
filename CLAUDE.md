# Medico — Project Context

## Stack
- Flutter/Dart, package: com.medico.app
- Backend: Supabase (eu-central-1/Frankfurt, RLS enabled) — Postgres, Auth, Realtime
- Push: Firebase Cloud Messaging, project medico-c769f
- Crash monitoring: Firebase Crashlytics
- Auth chain: Google Sign-In (primary, google_sign_in v7+ — singleton
  GoogleSignIn.instance, explicit initialize(), authenticate() not signIn())
  → Email OTP via Supabase signInWithOtp/verifyOTP (fallback)
  → SMS via Twilio (secondary fallback, trial = verified numbers only)
  → WhatsApp OTP (deferred, needs Meta Business Account approval first)

## Architecture rules
- main.dart stays minimal: app entry point + routing ONLY. Every screen
  lives in its own file under lib/screens/.
- Before creating any new screen/component file, state the exact path —
  never assume the file/directory already exists.
- UI-first workflow for new screens: build as dumb widgets before wiring
  backend, EXCEPT auth (already fully wired, not a template to follow
  for other screens yet).

## Locked design system — "Aurora sheet"
- Header (~210px): diagonal teal-to-blue gradient (#2A93C9 → #1D9E75),
  Medico wordmark centered, soft translucent white blob circles
- White rounded sheet overlaps header (negative margin-top)
- Input fields: light gray-green fill, ~12px radius, leading icon
- Primary buttons: teal-to-blue gradient, pill-shaped
- Numerals: Western digits default, Arabic/Western toggle in Settings

## Known-fragile behavior — do not break without being told
- GoogleSignInExceptionCode.canceled must return silently, no banner
- SplashScreen checks Supabase currentSession on launch → routes signed-in
  users straight to Home, skipping Sign In
- auth_error_banner.dart auto-dismisses after 5s; a new error cancels and
  restarts that timer rather than stacking
- OTP verify success state is INLINE on the same screen (spinner → green
  checkmark → auto-navigate), never a separate route
- Google Sign-In's error handler must debugPrint the raw exception before
  mapping it to a friendly message — active diagnostic for an open bug,
  don't remove it
- Sign Up password requirement: minimum 8 characters, NO character-type
  composition rule (letters-only, numbers-only, symbols-only, or any mix
  are all valid). Sign In password field only checks "not empty".

## Commands
- flutter pub get
- flutter run  (target: Medium Phone emulator, or Tecno Camon 20 Pro via USB)
- flutter clean && flutter pub get   (after dependency changes)

## Test devices
- Small Phone + Medium Phone Android Studio emulator presets
- Tecno Camon 20 Pro (real device, primary real-world target)

## Repo hygiene
- kickbacks-v2.vsix in repo root is intentional, not stray — leave it

---

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).