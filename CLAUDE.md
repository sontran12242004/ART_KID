# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ArtKids is a monorepo for a children's online art-learning platform (ages 4–12). It combines a cross-platform Flutter mobile app, a small Dart web scaffold at the repository root, NestJS microservices, and a Python AI inference worker.

The main working application is `apps/artkids_app`. The repository root also contains a bare Dart web app (`pubspec.yaml`, `web/`) that is not the primary product.

## Technology Stack

- **Mobile app**: Flutter 3.x+, Dart, Riverpod, go_router, Dio, Hive, flutter_painter, model_viewer_plus, Rive/Lottie, just_audio
- **Backend services**: NestJS 10 (TypeScript)
- **AI worker**: Python with FastAPI/uvicorn, Google Generative AI SDK, Celery/Redis
- **Shared packages**: TypeScript packages for DTOs (`shared-types`), API route constants (`api-contracts`), ESLint/tsconfig bases (`shared-configs`), and web design tokens (`ui-kit`)

## Repository Layout

```
D:\ART_KID
├── apps/artkids_app/            # Main Flutter app (iOS/Android)
├── packages/
│   ├── shared-types/            # Shared TypeScript DTOs
│   ├── api-contracts/           # API route constants
│   ├── shared-configs/          # tsconfig.base.json, eslint.base.json
│   └── ui-kit/                  # Web design tokens
├── services/
│   ├── ai-generation-service/
│   │   ├── orchestrator/        # NestJS job queue API
│   │   └── inference-worker/    # Python GPU worker
│   ├── fulfillment-service/     # NestJS shipping/tracking service
│   └── inventory-service/       # NestJS stock/SKU service
└── web/                         # Dart web scaffold (not the main app)
```

## Common Commands

### Flutter App (`apps/artkids_app`)

All Flutter commands should be run from `apps/artkids_app`.

```bash
cd apps/artkids_app

# Install dependencies
flutter pub get

# Run on Android emulator (dev flavor)
flutter run --flavor dev --dart-define=FLAVOR=dev -t lib/main.dart

# Run on a different flavor
flutter run --flavor staging --dart-define=FLAVOR=staging -t lib/main.dart
flutter run --flavor prod --dart-define=FLAVOR=prod -t lib/main.dart

# Build production app bundle
flutter build appbundle --flavor prod --dart-define=FLAVOR=prod -t lib/main.dart

# Static analysis
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/core/network/ai_job_poller_test.dart
```

VS Code launch configurations are provided in `apps/artkids_app/.vscode/launch.json`.

### Backend Services

Each NestJS service is independent. Run commands from the service directory.

```bash
cd services/fulfillment-service
npm install
npm run start:dev      # Development with watch
npm run start          # Production start
npm run build          # Build to dist/
```

The same applies to `services/inventory-service` and `services/ai-generation-service/orchestrator`.

### AI Inference Worker

```bash
cd services/ai-generation-service/inference-worker
pip install -r requirements.txt
python worker.py
```

### Shared TypeScript Packages

```bash
cd packages/shared-types
npm install
npm run build          # Compiles TypeScript to dist/
```

## Environment Configuration

The Flutter app reads environment variables from `apps/artkids_app/env/{flavor}.env`. These files are gitignored and are not present in the repository. You must create them before running the app.

Expected files:

- `apps/artkids_app/env/dev.env`
- `apps/artkids_app/env/staging.env`
- `apps/artkids_app/env/prod.env`

Key variables used by `lib/core/config/env_config.dart`:

- `API_BASE_URL` — backend gateway base URL (dev default: `http://10.0.2.2:3000/api` for Android emulator)
- `CDN_BASE_URL` — media CDN base URL
- `GEMINI_API_KEY` — Google Gemini API key for AI drawing analysis
- `ENABLE_MOCK_AI` — set `true` to use local mock AI results instead of calling Gemini
- `ENABLE_MOCK_ORDERS`, `ENABLE_MOCK_SHOP`, `ENABLE_MOCK_COURSES_PROGRESS` — default to `true` in dev if unset

## High-Level Architecture

### Flutter App: Feature-First Clean Architecture

`apps/artkids_app/lib` is organized by feature, with each feature split into layers:

```
features/<feature>/
├── data/
│   ├── datasources/     # Remote/local data sources (Dio, Hive, etc.)
│   ├── models/          # Data-transfer models with serialization
│   └── repositories/    # Repository implementations
├── domain/
│   ├── entities/        # Pure Dart business entities
│   ├── repositories/    # Repository interfaces
│   └── usecases/        # Feature-specific use cases
└── presentation/
    ├── providers/       # Riverpod providers/notifiers
    ├── screens/         # Flutter screens
    └── widgets/         # Feature widgets
```

Shared concerns live in `lib/core/`:

- `config/` — environment config
- `network/` — Dio client, interceptors, AI job polling, Gemini service
- `routing/` — go_router configuration (`app_router.dart`) and route paths
- `storage/` — Hive boxes and local storage service
- `theme/` — Parent vs Kid themes (`AppTheme.kid()` / `AppTheme.parent()`)
- `error/`, `firebase/`, `utils/`, `widgets/` — failures, FCM, COPPA helpers, shared widgets

### State Management and Routing

- State is managed with `flutter_riverpod`.
- Providers are declared in feature `presentation/providers/`.
- Navigation uses `go_router`; routes and path constants are centralized in `core/routing/`.
- `app_mode_provider` toggles between `AppMode.parent` and `AppMode.kid`, switching the theme and available routes.

### Parent Mode vs Kid Mode

The app has two distinct UX modes:

- **Parent Mode**: login/registration, subscription/shop, order tracking, child progress, PIN setup.
- **Kid Mode**: simplified large-touch UI, drawing lessons, matching game, badges/3D models, voice guidance (TTS).

Switching from Kid Mode back to Parent Mode requires passing a PIN gate (`kid_pin_gate_screen.dart`).

### Offline Storage (Hive)

Hive is initialized in `bootstrap.dart`. Important boxes:

- `settings`
- `lessonCache`
- `creatureCache`
- `matchingProgress` — typed `MatchingGameProgress`
- `completedPictures` — typed `CompletedPicture`

`MatchingGameProgress` and `GamePhase` use Hive `typeId` 20 and 21, respectively. Do not reuse these IDs. The project intentionally does not use `hive_generator`; adapters are hand-written.

### AI Drawing-to-Creature Flow

1. Child draws on the canvas (`drawing_canvas` feature) or uses the matching-game flow.
2. The drawing is sent to the AI orchestrator or analyzed directly via `GeminiService.analyzeDrawing()` (`core/network/gemini_service.dart`).
3. `CreatureGenNotifier` (`ai_creature/presentation/providers/creature_generation_provider.dart`) manages the state machine: `analyzing` → `generatingModel` → `ready`/`error`.
4. The result maps to a bundled 2D/3D asset (`features/ai_creature/data/creature_3d_assets.dart`) displayed in `CreatureViewerScreen`.
5. The `gemini_service.dart` provider tries multiple Gemini model names (`gemini-3.6-flash`, `gemini-1.5-flash`, `gemini-2.0-flash-exp`) and parses a strict JSON response shape.

### Matching Game Flow

`features/matching_game/` implements a draw-then-match educational game:

1. `PictureSelectionScreen` — choose a picture set (e.g., `living_room`).
2. `DrawingScreen` — draw each animal sequentially to unlock stickers.
3. `MatchingScreen` — drag stickers into drop targets on the background image.
4. Progress is persisted to Hive via `MatchingGameProgress` so children can resume.
5. Completed pictures are saved to the `completedPictures` box and shown in `CompletedGalleryScreen`.

### Backend Microservices

- **AI Orchestrator** (`services/ai-generation-service/orchestrator`): NestJS CPU-bound service that accepts drawing submissions, creates jobs, and exposes polling endpoints. Designed to enqueue jobs to Redis/BullMQ for GPU workers.
- **AI Inference Worker** (`services/ai-generation-service/inference-worker`): Python worker that consumes jobs, calls Gemini Vision, and returns creature metadata.
- **Fulfillment Service**: manages shipments, carrier integrations (VNPost, GHN, GHTK), and tracking webhooks.
- **Inventory Service**: manages art-kit SKUs, available/reserved stock, and reorder thresholds.

Shared API route constants are in `packages/api-contracts/src/index.ts`. Shared DTOs are in `packages/shared-types/src/index.ts`.

## Development Notes

- Flavors are configured in `apps/artkids_app/android/app/build.gradle.kts` and `apps/artkids_app/.vscode/launch.json`.
- The analyzer excludes `build/`, `android/`, and `ios/` in `apps/artkids_app/analysis_options.yaml`.
- Several features default to mocked backend data in dev via `EnvConfig` flags; disable mocks by setting the corresponding env variable to `false`.
- The root `pubspec.yaml` and `web/` directory are a separate Dart web scaffold unrelated to the Flutter mobile app. Do not confuse them.
