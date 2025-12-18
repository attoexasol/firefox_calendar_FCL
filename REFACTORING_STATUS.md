# Refactoring Status

## ✅ Completed

1. **Folder Structure Created**
   - `lib/core/constants/` ✅
   - `lib/core/theme/` ✅
   - `lib/core/utils/` ✅
   - `lib/core/widgets/` ✅
   - `lib/services/` ✅
   - `lib/routes/` ✅
   - All feature folders created ✅

2. **Core Files Moved**
   - Theme files → `lib/core/theme/` ✅
   - Services → `lib/services/` ✅
   - Routes → `lib/routes/` ✅
   - Theme imports updated ✅

3. **Main.dart Updated**
   - Imports updated to new paths ✅

## 🔄 In Progress

- Organizing feature files (auth, dashboard, calendar, hours, payroll, settings, profile)
- Updating all import statements
- Moving shared widgets to `core/widgets/`

## 📋 Remaining Tasks

### Feature Organization

1. **Auth Feature** (`lib/features/auth/`)
   - Move controllers → `controller/`
   - Move views → `view/`
   - Move widgets → `view/widgets/` (or keep in view)
   - Move service → `service/` (if auth-specific)
   - Create models → `model/`

2. **Dashboard Feature** (`lib/features/dashboard/`)
   - Move controller → `controller/` ✅ (already done)
   - Move view → `view/`
   - Move widgets → `widgets/`

3. **Other Features** (Calendar, Hours, Payroll, Settings, Profile)
   - Similar structure as above

4. **Shared Widgets**
   - `top_bar.dart` → `lib/core/widgets/`
   - `bottom_nav.dart` → `lib/core/widgets/`

5. **Update All Imports**
   - Update theme imports: `app/theme/` → `core/theme/`
   - Update service imports: `core/services/` → `services/`
   - Update route imports: `app/routes/` → `routes/`
   - Update feature imports to new structure

6. **Update Bindings**
   - Update `initial_binding.dart` with new paths

7. **Cleanup**
   - Delete old `app/` folder (except bindings)
   - Delete old `presentation/` folder
   - Delete old `core/service/` folder

## Import Path Changes

### Theme
- Old: `app/theme/app_theme.dart`
- New: `core/theme/app_theme.dart`

### Services
- Old: `core/service/auth_service.dart` or `core/services/auth_service.dart`
- New: `services/auth_service.dart`

### Routes
- Old: `app/routes/app_routes.dart`
- New: `routes/app_routes.dart`

### Features
- Old: `presentation/auth/controllers/login_controller.dart`
- New: `features/auth/controller/login_controller.dart`
- Old: `presentation/auth/views/login_screen.dart`
- New: `features/auth/view/login_screen.dart`

