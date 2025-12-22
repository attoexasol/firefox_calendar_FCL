# 📍 Codebase Location Guide

## 🗂️ **Project Structure Overview**

```
lib/
├── main.dart                          # App entry point
├── features/                          # Feature modules
│   ├── calendar/                     # Calendar feature
│   ├── hours/                         # Hours/Time tracking feature
│   ├── dashboard/                     # Dashboard feature
│   ├── auth/                          # Authentication feature
│   ├── settings/                     # Settings feature
│   ├── payroll/                       # Payroll feature
│   └── profile/                       # Profile feature
├── services/                          # API services
│   └── auth_service.dart             # All API calls
├── core/                              # Core utilities
│   ├── theme/                        # App themes & colors
│   └── widgets/                      # Reusable widgets
├── routes/                            # Route definitions
│   └── app_routes.dart               # Route constants
└── app/                               # App configuration
    ├── routes/                        # Route pages
    └── bindings/                      # Dependency injection
```

---

## 📅 **Calendar Feature Locations**

### **Controllers**
- **Main Calendar Controller**: `lib/features/calendar/controller/calendar_controller.dart`
  - Event fetching (`fetchAllEvents()`)
  - Scope filtering (`_applyScopeFilter()`)
  - Event mapping (`_mapEventToMeeting()`)
  - User filtering (`isUserInvited()`)

- **Create Event Controller**: `lib/features/calendar/controller/create_event_controller.dart`
  - Event creation (`handleSubmit()`)
  - Form management
  - Event type mapping

### **Views**
- **Calendar Screen**: `lib/features/calendar/view/calendar_screen.dart`
  - Main calendar UI
  - Day/Week/Month views
  - Event rendering

- **Create Event Screen**: `lib/features/calendar/view/create_event_screen.dart`
  - Event creation form

- **Event Details Dialog**: `lib/features/calendar/view/event_details_dialog.dart`
  - Event details modal

---

## ⏰ **Hours Feature Locations**

### **Controller**
- **Hours Controller**: `lib/features/hours/controller/hours_controller.dart`
  - Check-in/Check-out logic (`checkIn()`, `checkOut()`)
  - Work logs management
  - Time tracking
  - API integration for saving hours

### **View**
- **Hours Screen**: `lib/features/hours/view/hours_screen.dart`
  - Hours display UI
  - Work logs list
  - Summary card

---

## 🔌 **API Service Locations**

### **Auth Service** (All API Calls)
- **Location**: `lib/services/auth_service.dart`

**Key Methods**:
- `createEvent()` - Create calendar event
- `getAllEvents()` - Get all events (Everyone view)
- `getSingleEvent()` - Get single event details
- `createUserHours()` - Save work hours (check-in/check-out)
- `loginUser()` - Normal login
- `biometricLogin()` - Biometric login
- `registerUser()` - User registration
- `logoutUser()` - User logout

---

## 🎨 **UI Components Locations**

### **Top Bar** (Check-in/Check-out Buttons)
- **Location**: `lib/core/widgets/top_bar.dart`
- **Features**: Start Time & End Time buttons

### **Bottom Navigation**
- **Location**: `lib/core/widgets/bottom_nav.dart`

### **Theme & Styles**
- **Colors**: `lib/core/theme/app_colors.dart`
- **Text Styles**: `lib/core/theme/app_text_styles.dart`
- **Theme**: `lib/core/theme/app_theme.dart`

---

## 🛣️ **Routes & Navigation**

### **Route Definitions**
- **Location**: `lib/routes/app_routes.dart`
- **Route Constants**: `/calendar`, `/hours`, `/dashboard`, etc.

### **Route Pages**
- **Location**: `lib/app/routes/app_pages.dart`
- **Page Registration**: All GetPage definitions

---

## 🔧 **Dependency Injection**

### **Initial Bindings**
- **Location**: `lib/app/bindings/initial_binding.dart`
- **Controllers Registered**: All feature controllers

---

## 📋 **Key Feature Locations Summary**

| Feature | Controller | View | API Method |
|---------|-----------|------|------------|
| **Calendar** | `calendar_controller.dart` | `calendar_screen.dart` | `getAllEvents()` |
| **Create Event** | `create_event_controller.dart` | `create_event_screen.dart` | `createEvent()` |
| **Hours** | `hours_controller.dart` | `hours_screen.dart` | `createUserHours()` |
| **Check-in/out** | `hours_controller.dart` | `top_bar.dart` | `createUserHours()` |
| **Event Details** | `calendar_controller.dart` | `event_details_dialog.dart` | `getSingleEvent()` |

---

## 🔍 **Quick Find Guide**

### **Where to find...**

**Check-in/Check-out buttons**: `lib/core/widgets/top_bar.dart` (lines 81-129)

**Hours saving logic**: `lib/features/hours/controller/hours_controller.dart`
- `checkIn()` - line ~263
- `checkOut()` - line ~288
- `createUserHours()` API call - line ~326

**Event fetching**: `lib/features/calendar/controller/calendar_controller.dart`
- `fetchAllEvents()` - line ~125
- `_applyScopeFilter()` - line ~334

**Event creation**: `lib/features/calendar/controller/create_event_controller.dart`
- `handleSubmit()` - line ~240

**API methods**: `lib/services/auth_service.dart`
- `createEvent()` - line ~446
- `getAllEvents()` - line ~564
- `getSingleEvent()` - line ~513
- `createUserHours()` - line ~629

**Myself view filtering**: `lib/features/calendar/controller/calendar_controller.dart`
- `_applyScopeFilter()` - line ~334
- `isUserInvited()` - line ~470

**Event refresh**: `lib/features/calendar/controller/calendar_controller.dart`
- `refreshEvents()` - line ~314

---

## 📝 **Current File You're Viewing**

**Hours Controller**: `lib/features/hours/controller/hours_controller.dart`
- **Total Lines**: 421
- **Key Sections**:
  - Check-in/Check-out state (lines 30-34)
  - `checkIn()` method (line ~263)
  - `checkOut()` method (line ~288)
  - `createUserHours()` API integration (line ~326)

---

## 🎯 **Most Important Files for Calendar & Hours**

1. **Calendar Controller**: `lib/features/calendar/controller/calendar_controller.dart`
2. **Hours Controller**: `lib/features/hours/controller/hours_controller.dart`
3. **Auth Service**: `lib/services/auth_service.dart`
4. **Top Bar**: `lib/core/widgets/top_bar.dart`
5. **Calendar Screen**: `lib/features/calendar/view/calendar_screen.dart`

---

## 💡 **Need to Find Something Specific?**

- **Event creation logic** → `create_event_controller.dart`
- **Event fetching** → `calendar_controller.dart` → `fetchAllEvents()`
- **Check-in/out buttons** → `top_bar.dart`
- **Hours saving** → `hours_controller.dart` → `checkOut()`
- **API calls** → `auth_service.dart`
- **Routes** → `app_routes.dart` & `app_pages.dart`

