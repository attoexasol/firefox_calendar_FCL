# Flutter Project Refactoring Guide

## New Folder Structure

The project has been refactored to follow a feature-based architecture:

```
lib/
├── app/                          # App-level configuration
│   ├── bindings/                 # Dependency injection
│   ├── routes/                   # Navigation & routing
│   └── theme/                    # UI theme configuration
│
├── core/                         # Core/shared functionality
│   ├── services/                 # Shared services
│   │   ├── auth_service.dart
│   │   └── biometric_service.dart
│   ├── widgets/                  # Shared/reusable widgets
│   │   ├── top_bar.dart
│   │   └── bottom_nav.dart
│   └── models/                   # Shared models (if any)
│
├── features/                     # Feature-based modules
│   ├── auth/                     # Authentication feature
│   │   ├── controllers/
│   │   ├── views/
│   │   ├── widgets/
│   │   └── bindings/
│   │
│   ├── dashboard/                # Dashboard feature
│   │   ├── controllers/
│   │   │   └── dashboard_controller.dart ✅ MOVED
│   │   ├── views/
│   │   │   └── dashboard_screen.dart
│   │   └── widgets/
│   │       ├── dashboard_welcome_card.dart
│   │       ├── dashboard_metrics_grid.dart
│   │       ├── dashboard_next_event_card.dart
│   │       └── dashboard_quick_action_cards.dart
│   │
│   ├── calendar/                 # Calendar feature
│   │   ├── controllers/
│   │   ├── views/
│   │   └── models/
│   │
│   ├── hours/                    # Hours tracking feature
│   │   ├── controllers/
│   │   ├── views/
│   │   └── models/
│   │
│   ├── payroll/                  # Payroll feature
│   │   ├── controllers/
│   │   ├── views/
│   │   └── models/
│   │
│   ├── settings/                 # Settings feature
│   │   ├── controllers/
│   │   ├── views/
│   │   └── widgets/
│   │
│   └── profile/                  # Profile feature
│       ├── controllers/
│       ├── views/
│       └── widgets/
│
└── main.dart                     # App entry point
```

## Migration Status

### ✅ Completed
- Core services moved to `lib/core/services/`
- Service imports updated from `core/service/` to `core/services/`
- Dashboard controller moved to `lib/features/dashboard/controllers/`

### 🔄 In Progress
- Moving remaining feature files
- Updating all import statements
- Moving shared widgets to `core/widgets/`

### 📋 Remaining Tasks
1. Move auth feature files
2. Move calendar feature files
3. Move hours feature files
4. Move payroll feature files
5. Move settings feature files
6. Move profile feature files
7. Move shared widgets (top_bar, bottom_nav)
8. Update all import statements
9. Update app_pages.dart and initial_binding.dart
10. Fix typos (wiggets → widgets, dashbord → dashboard)

## Import Path Changes

### Services
- Old: `core/service/auth_service.dart`
- New: `core/services/auth_service.dart`

### Dashboard
- Old: `presentation/auth/controllers/dashboard_controller.dart`
- New: `features/dashboard/controllers/dashboard_controller.dart`

### Shared Widgets
- Old: `presentation/auth/views/sections/top_bar.dart`
- New: `core/widgets/top_bar.dart`

## Benefits

1. **Better Organization**: Code is organized by feature, making it easier to find and maintain
2. **Clear Separation**: UI, logic, services, and models are clearly separated
3. **Scalability**: Easy to add new features without cluttering existing code
4. **Maintainability**: Each feature is self-contained and easier to understand
5. **Best Practices**: Follows Flutter/Dart best practices for project structure

