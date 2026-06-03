# Odlikas Screen

Flutter tablet/screen app — a companion for the Odlikas mobile app for the Croatian national e-grade system E-Dnevnik. Pairs with the mobile app via QR code and provides an extended interface on a secondary display, optimised for landscape format.

## Features

- **Grades** — view current grades by subject with detailed scoring tables and visual grade wheel
- **Calendar** — personal calendar with upcoming deadlines and custom event creation
- **MathNotes** — digital whiteboard for handwriting and drawing math problems with AI solving (DeepSeek + Mathpix OCR), undo/redo, shapes, text and image import; notes auto-saved to a gallery
- **Pomodoro** — built-in Pomodoro timer (25/5/15 min) with session and streak tracking via the backend API, daily cap of 8 sessions and optimistic updates
- **To-Do** — task list with creation and status tracking
- **Files** — PDF viewer with page selection
- **Ljestvica** — school leaderboard showing top students by grade delta and Pomodoro streak score, with class, school and programme rankings

## Pairing with the Mobile App

The screen displays a QR code that the student scans with the Odlikas mobile app. After scanning, the screen receives a Bearer token which is stored in Hive and used for all subsequent API calls to the Odlikas backend.

## Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter (Dart), landscape mode |
| State management | Provider + ChangeNotifier |
| REST API | `http` package with Bearer token auth (token from Hive) |
| Authentication | QR code pairing → JWT token stored in Hive |
| AI (MathNotes) | DeepSeek API (problem solving) + Mathpix (OCR) |
| Cloud database | Cloud Firestore |
| Local storage | Hive |
| Animations | Lottie |

## Project Structure

```
lib/
├── main.dart                        # App entry point, routing, MultiProvider setup
├── responsive.dart                  # Responsive layout utilities
├── custom_adapters.dart             # Hive adapters (WhiteboardData, Uint8List)
├── exceptions/
│   └── app_exceptions.dart          # Typed ApiException class
├── models/
│   ├── grades.dart                  # Grade and subject models
│   ├── specific_subject.dart        # Subject detail model
│   ├── student_profile.dart         # Student profile model
│   ├── task.dart                    # Task model (ToDoList)
│   └── tests.dart                   # Test and deadline models
├── viewmodels/
│   ├── viewmodel.dart               # HomePageViewModel (grades, profile)
│   └── test_viewmodel.dart          # TestViewmodel (tests)
├── database/
│   ├── api/
│   │   ├── api_service.dart         # HTTP service (grades, profile, tests)
│   │   ├── pomodoro_api_service.dart # Pomodoro API (GetStreak, CompleteSession)
│   │   ├── deepseek_service.dart    # DeepSeek AI service
│   │   └── matpix_ai_solving.dart   # Mathpix OCR service
│   ├── firebase_pomodoro_service.dart # Firestore Pomodoro sync
│   ├── task_service.dart            # Firestore task service
│   └── firebase_options.dart
└── pages/
    ├── SetupPage/                   # Initial screen setup
    ├── QRCodePage/                  # QR code for pairing with mobile app
    ├── HomePage/                    # Main dashboard (4-quadrant layout)
    │   └── widgets/
    │       └── grade_wheel.dart     # Visual grade display
    ├── Grades/                      # Subject grades list
    ├── SpecificSubject/             # Subject detail with grades and notes
    ├── Calendar/                    # Calendar with events
    ├── ToDoList/                    # Task list
    ├── PomodoroTimer/               # Pomodoro timer
    │   ├── pomodoro_notifier.dart   # Timer state (ChangeNotifier)
    │   ├── pomodoro_timer_page.dart # UI page
    │   └── widgets/
    │       ├── pomodoro_container.dart  # Timer display and buttons
    │       └── session_circles.dart    # 8 daily session circles
    ├── MathNotes/                   # AI math whiteboard
    │   ├── math_notes.dart          # Main whiteboard
    │   ├── Core/                    # Types and whiteboard state
    │   ├── Managers/                # Drawing, text, image, shape, AI, storage managers
    │   ├── Shapes/                  # Shape definitions and painters
    │   ├── TextAdding/              # Text element
    │   ├── ImagesAdding/            # Image element
    │   ├── saveWhiteboards/         # Hive persistence and gallery
    │   └── widgets/                 # Toolbar and UI components
    ├── SimilarTasks/                # Similar AI-generated tasks
    ├── SolutionStepsPage/           # Step-by-step AI solution display
    └── UploadFiles/                 # PDF viewer and page selector
```

## Getting Started

### Prerequisites

- Flutter SDK `^3.5.3`
- Dart SDK `^3.5.3`
- Android Studio or VS Code with the Flutter extension
- Android tablet or emulator
- Access to the Odlikas backend API
- Odlikas mobile app for pairing

### Setup

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd odlikas_ekran
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**

   Create a `.env` file in the project root (next to `pubspec.yaml`):
   ```env
   API_BASE_URL=http://<backend-ip>:<port>
   DEEPSEEK_API_KEY=your_deepseek_api_key
   MATHPIX_APP_ID=your_mathpix_app_id
   MATHPIX_APP_KEY=your_mathpix_app_key
   ```

   > The `.env` file is listed in `.gitignore` and **must never be committed**.

4. **Firebase setup**

   The `google-services.json` file (Android) is required for Firebase features. Contact a team member to obtain it — it is not stored in the repository.

5. **Run the app**
   ```bash
   flutter run
   ```

   The app automatically locks to landscape orientation and enables immersive sticky mode.

### Running tests

```bash
flutter test
```

59 tests across 7 files covering exception classes, all data models (Task, Grades, StudentProfile, Tests, SubjectDetails), LeaderboardEntry JSON parsing, and RecommendationViewModel business logic.

### Static analysis

```bash
flutter analyze
```

### CI/CD

A GitHub Actions workflow runs on every push and pull request to `main`. It installs dependencies, runs static analysis, and executes the full test suite. See `.github/workflows/ci.yml`.

## Authentication Flow

1. The screen generates and displays a QR code containing a unique `screenId`
2. The student scans the QR code with the Odlikas mobile app
3. The backend ties the `screenId` to the student's account and returns a Bearer token
4. The token is stored in Hive (`user_credentials` box, key `token`)
5. All subsequent API calls (`ApiService`, `PomodoroApiService`) read the token from Hive and attach it as an `Authorization: Bearer` header

## Environment Variables

| Variable | Description |
|---|---|
| `API_BASE_URL` | Base URL of the Odlikas ASP.NET backend API |
| `DEEPSEEK_API_KEY` | DeepSeek API key for AI math problem solving |
| `MATHPIX_APP_ID` | Mathpix App ID for math OCR |
| `MATHPIX_APP_KEY` | Mathpix App Key for math OCR |

Sensitive values are never hardcoded. All secrets are loaded from the `.env` file at startup.

## Contributing

1. Branch off `main` for new features: `git checkout -b feature/feature-name`
2. Use conventional commit messages: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
3. Open a pull request against `main`

## Team

Built by the **Odlikas** team for the Mc2 competition.
