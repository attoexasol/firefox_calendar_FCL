# Calendar Feature - Comprehensive Analysis

## 📸 Image Analysis

### Visual Structure
The calendar screen displays a **Week View** with the following components:

1. **Top App Bar**
   - Firefox Training logo (left)
   - "Calendar" title (center)
   - Play/Stop buttons (right)

2. **View Controls**
   - **"Show calendar by"**: Day/Week/Month toggle (Week selected - orange highlight)
   - **"Show schedule for"**: Everyone/Myself toggle (Everyone selected - orange highlight)

3. **Date Navigation**
   - Previous/Next arrows
   - Current range: "Dec 29 - Jan 4, 2026"
   - "Today" button

4. **Calendar Grid Header** (Critical for horizontal scroll sync)
   - **Days/Dates Row**: Shows "S 29", "M 30", "T 31", "W 1" (Tuesday highlighted with orange border)
   - **User Avatars Row**: 
     - "Time" label (80px width)
     - User columns (150px each): "AM" (Aman22), "LE" (Lenita)
     - Extends horizontally (more users off-screen)

5. **Calendar Grid Body** (Critical for scroll sync)
   - **Time Column**: "12:00 AM", "01:00 AM", "02:00 AM", "03:00 AM" (extends vertically)
   - **Event/Work Hour Grid**: 
     - Columns align with user avatars above
     - Rows align with time slots
     - Empty cells visible (would show events/work hours)

6. **Floating Action Button**: Orange "+" button (bottom right)

7. **Bottom Navigation**: Calendar, Hours, Dashboard, Payroll, Settings

### Key Observation
The header (days/dates + user avatars) and body (time grid) must scroll horizontally **together** as a single unit, while the body scrolls vertically independently.

---

## 🏗️ Calendar Feature Structure

### Directory Layout
```
lib/features/calendar/
├── controller/
│   ├── calendar_controller.dart      (1,292 lines) - Main calendar logic
│   └── create_event_controller.dart  (777 lines) - Event creation logic
└── view/
    ├── calendar_screen.dart          (3,928 lines) - Main calendar UI
    ├── cell_cards_modal.dart         (357 lines) - Cell overflow modal
    ├── create_event_screen.dart      (312 lines) - Event creation UI
    ├── event_details_dialog.dart    (492 lines) - Event details popup
    └── hour_details_dialog.dart      (359 lines) - Work hour details popup
```

---

## 🎯 Core Components

### 1. CalendarController (`calendar_controller.dart`)

**Responsibilities:**
- State management (view type, scope, current date)
- API integration (fetch events, work hours)
- Data filtering (everyone/myself, date ranges)
- Meeting/work hour data transformation
- User data management

**Key Observable State:**
```dart
RxString viewType = 'week'           // 'day', 'week', 'month'
RxString scopeType = 'everyone'      // 'everyone', 'myself'
Rx<DateTime> currentDate              // Current selected date
Rx<DateTime?> selectedWeekDate       // Selected day in week view
RxList<Meeting> allMeetings           // All meetings from API
RxList<Meeting> meetings              // Filtered meetings
RxList<WorkHour> workHours            // Work hours for overlay
RxBool isLoadingEvents               // Loading state
RxString eventsError                  // Error state
```

**Key Methods:**
- `fetchAllEvents()` - Fetches events from API
- `fetchWorkHours()` - Fetches work hours for calendar overlay
- `filterMeetings()` - Filters by scope (everyone/myself)
- `getMeetingsByDate()` - Groups meetings by date
- `getCurrentWeekDates()` - Calculates week date range
- `getTimeRange()` - Determines visible time range from events
- `refreshCalendarData()` - Refreshes all calendar data

**Data Models:**
- `Meeting` - Event/meeting data structure
- `WorkHour` - Work hours data structure
- `TimeRange` - Time range for calendar display

---

### 2. CalendarScreen (`calendar_screen.dart`)

**Architecture:**
- Uses `CustomScrollView` with `Slivers` for sticky header behavior
- Main structure:
  ```
  Scaffold
    └── Stack
        ├── SafeArea
        │   └── CustomScrollView
        │       ├── SliverToBoxAdapter (Top filters)
        │       └── SliverFillRemaining (Calendar grid)
        ├── Event Details Listener
        └── Hour Details Listener
  ```

**View Types:**

#### Week View (`_buildWeekGridWithHeader`)
- **Structure:**
  ```
  SingleChildScrollView (horizontal)
    └── Column
        ├── _buildWeekHeaderContent (Days + User avatars)
        └── SizedBox (fixed height)
            └── SingleChildScrollView (vertical)
                └── _buildWeekTimeGridContentNoScroll (Time grid)
  ```
- **Header Height:** 168px (Days row: 60px + User header: 80px + spacing: 28px)
- **Total Width:** 80px (time column) + (days × users per day × 150px)

#### Day View (`_buildDayGridWithHeader`)
- **Structure:**
  ```
  SingleChildScrollView (horizontal)
    └── Column
        ├── _buildDayHeaderContent (User avatars)
        └── SizedBox (fixed height)
            └── SingleChildScrollView (vertical)
                └── _buildDayTimeGridContentNoScroll (Time grid)
  ```
- **Header Height:** 80px
- **Total Width:** 80px (time column) + (users × 150px)

#### Month View (`_buildMonthView`)
- Traditional calendar grid layout

**Key UI Components:**

1. **Header Content Builders:**
   - `_buildWeekHeaderContent()` - Days/dates row + user avatars row
   - `_buildDayHeaderContent()` - User avatars row only
   - `_buildDayDateItem()` - Individual day/date cell with selection highlight

2. **Time Grid Builders:**
   - `_buildWeekTimeGridContentNoScroll()` - Week time slots (no horizontal scroll wrapper)
   - `_buildDayTimeGridContentNoScroll()` - Day time slots (no horizontal scroll wrapper)
   - Both return `Column` of time slot rows

3. **Cell Content Builder:**
   - `_buildCellContent()` - Renders events and work hours in cells
     - Combines meetings and work hours
     - Sorts by start time
     - Handles overflow (shows "+N more" indicator)
     - Renders work hour background blocks
     - Renders meeting/work hour cards

4. **Event/Work Hour Cards:**
   - `_buildMeetingCard()` - Meeting event card
   - `_buildWorkHourCard()` - Work hour card

**Scrolling Implementation:**
- ✅ **Horizontal Scroll:** Single `SingleChildScrollView` wraps both header and body
- ✅ **Vertical Scroll:** Separate `SingleChildScrollView` inside body for time slots
- ✅ **Synchronization:** Header and body share same horizontal scroll container
- ✅ **Height Management:** Uses `LayoutBuilder` to calculate available space

---

### 3. CreateEventController (`create_event_controller.dart`)

**Status:** Currently commented out (lines 1-777)

**Intended Purpose:**
- Manage event creation form state
- Handle event type selection
- Form validation
- API integration for creating/editing events

---

### 4. Supporting Views

#### `cell_cards_modal.dart`
- Displays overflow events/work hours when cell has too many items
- Shows all items in a scrollable modal

#### `create_event_screen.dart`
- Event creation/editing form
- Date/time pickers
- Event type selection
- Attendee management

#### `event_details_dialog.dart`
- Event details popup
- Edit/delete actions
- Attendee list

#### `hour_details_dialog.dart`
- Work hour details popup
- Shows login/logout times
- Total hours calculation

---

## 🔄 Data Flow

### 1. Initialization
```
CalendarScreen.build()
  └── CalendarController.onInit()
      ├── _loadUserData()
      ├── fetchAllEvents()
      └── fetchWorkHours()
```

### 2. Event Fetching
```
fetchAllEvents()
  ├── Determine date range (based on viewType)
  ├── Call AuthService.getAllEvents(range, scope)
  ├── Transform API response to Meeting objects
  ├── Filter by scope (everyone/myself)
  └── Update meetings observable
```

### 3. Work Hours Fetching
```
fetchWorkHours()
  ├── Call AuthService.getCalendarUserHours()
  ├── Transform to WorkHour objects
  └── Update workHours observable
```

### 4. Rendering
```
CalendarScreen.build()
  └── Obx(() => ...) // Reactive to controller state
      └── _buildWeekGridWithHeader()
          ├── Get week dates
          ├── Get meetings by date
          ├── Get users by date
          ├── Calculate total width
          └── Build header + body with synchronized scroll
```

### 5. Cell Content Rendering
```
_buildCellContent()
  ├── Combine meetings + work hours
  ├── Sort by start time
  ├── Determine visible items (max 3)
  ├── Calculate overflow count
  └── Render:
      ├── Work hour background (if spans hour)
      ├── Meeting/work hour cards
      └── Overflow indicator (if > 3 items)
```

---

## 🎨 UI Features

### Color System
- **User Avatars:** Color-coded by user email hash
- **Events:** Color-coded by event type/category
- **Work Hours:** Green background (light: #D1FAE5, dark: #166534 with alpha)
- **Selected Day:** Orange border highlight

### Responsive Design
- **Time Column:** Fixed 80px width
- **User Columns:** Fixed 150px width per user
- **Cell Height:** Minimum 80px, grows with content
- **Header Heights:** 
  - Week: 168px (days row + user row)
  - Day: 80px (user row only)

### Overflow Handling
- **Max Visible Items:** 3 per cell
- **Overflow Indicator:** "+N more" button
- **Modal Display:** Clicking overflow opens `CellCardsModal` with all items

---

## 🔍 Key Implementation Details

### Horizontal Scroll Synchronization

**Current Implementation:**
```dart
SingleChildScrollView (horizontal)  // ← Single scroll container
  └── Column
      ├── Header (Days + Users)     // ← No internal horizontal scroll
      └── Body (Time Grid)           // ← No internal horizontal scroll
```

**Why It Works:**
- Header and body are siblings in the same `Column`
- Both are children of the same horizontal `SingleChildScrollView`
- When horizontal scroll occurs, both move together
- Body has its own vertical `SingleChildScrollView` for time slots

### User Column Calculation

**Week View:**
- Each day can have different users
- Users are extracted from meetings for each day
- Total width = 80px + Σ(users per day × 150px)

**Day View:**
- Single set of users for the day
- Total width = 80px + (users × 150px)

### Time Range Calculation

**Dynamic Range:**
- Calculated from all visible events
- `TimeRange.startHour` = earliest event hour
- `TimeRange.endHour` = latest event hour + 1
- Defaults to 8 AM - 6 PM if no events

### Event/Work Hour Overlay

**Rendering Order:**
1. Work hour background (if spans hour) - behind
2. Meeting/work hour cards - foreground
3. Overflow indicator - top

**Work Hour Background:**
- Shown if work hour login/logout spans the hour slot
- Light green tint (light mode) or dark green with alpha (dark mode)

---

## 📊 Data Models

### Meeting
```dart
class Meeting {
  String id;
  String title;
  String date;              // YYYY-MM-DD
  String startTime;         // HH:mm
  String endTime;           // HH:mm
  String userId;            // User ID
  String creatorEmail;      // Creator email
  List<String> attendees;    // Attendee emails
  String category;          // 'meeting' or 'work_hour'
  // ... other fields
}
```

### WorkHour
```dart
class WorkHour {
  String id;
  String title;
  String date;              // YYYY-MM-DD
  String loginTime;         // HH:mm
  String logoutTime;        // HH:mm
  double totalHours;
  String status;            // 'approved', 'pending'
  String userId;
  // ... other fields
}
```

---

## 🐛 Potential Issues & Observations

### 1. Scrolling Implementation
✅ **Current State:** Correctly implemented with single horizontal scroll container
- Header and body scroll together horizontally
- Body scrolls independently vertically

### 2. Performance Considerations
- Large number of users/days could impact rendering
- Consider virtualization for very long time ranges
- Cell content rendering is optimized with overflow handling

### 3. Data Synchronization
- Events and work hours fetched separately
- Refresh needed after creating/updating events
- Dashboard controller triggers calendar refresh on work hour changes

### 4. CreateEventController
⚠️ **Status:** Currently commented out
- Event creation may use different controller/implementation
- Check `create_event_screen.dart` for actual implementation

---

## 🎯 Summary

### Strengths
1. ✅ **Synchronized Horizontal Scrolling:** Header and body scroll together
2. ✅ **Reactive UI:** Uses GetX observables for automatic updates
3. ✅ **Flexible Views:** Supports day/week/month views
4. ✅ **Overflow Handling:** Gracefully handles many events per cell
5. ✅ **Work Hour Integration:** Shows work hours as background blocks
6. ✅ **User-Friendly:** Clear visual hierarchy and interactions

### Architecture Highlights
1. **Separation of Concerns:** Controller handles logic, View handles UI
2. **State Management:** GetX provides reactive state management
3. **API Integration:** Centralized in AuthService
4. **Modular Components:** Each view type has dedicated builders
5. **Reusable Helpers:** Cell content builder used across views

### File Statistics
- **Total Lines:** ~6,500+ lines across calendar feature
- **Main Screen:** 3,928 lines (calendar_screen.dart)
- **Main Controller:** 1,292 lines (calendar_controller.dart)
- **Complexity:** High (due to multiple view types and scroll synchronization)

---

## 📝 Recommendations

1. **Code Organization:**
   - Consider splitting `calendar_screen.dart` into smaller widget files
   - Extract cell rendering logic to separate widget class
   - Create dedicated header widget classes

2. **Performance:**
   - Implement lazy loading for time slots
   - Consider using `ListView.builder` for time slots instead of `Column`
   - Cache user avatar colors

3. **Testing:**
   - Add unit tests for date range calculations
   - Test scroll synchronization behavior
   - Test overflow handling with many events

4. **Documentation:**
   - Add inline documentation for complex calculations
   - Document scroll synchronization approach
   - Add comments for time range logic

---

*Analysis completed on: 2025-12-30*


