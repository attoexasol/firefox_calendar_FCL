# Calendar Screen Sections

This directory contains refactored sections extracted from `calendar_screen.dart` for better code organization and maintainability.

## Extracted Sections

### ✅ State Sections (`calendar_states.dart`)
- `CalendarLoadingState` - Loading state widget
- `CalendarErrorState` - Error state widget with retry button
- `CalendarEmptyState` - Empty state widget

### ✅ Filter Sections (`calendar_filters.dart`)
- `ShowCalendarBySection` - Day/Week/Month view selector
- `ShowScheduleForSection` - Everyone/Myself scope selector
- `DateNavigationSection` - Date navigation with previous/next/today buttons

### ✅ Widget Components
- `calendar_tab_button.dart` - Reusable tab button widget
- `hoverable_card.dart` - Card widget with hover effect
- `calendar_cards.dart` - Meeting and work hour card widgets
  - `MeetingCard` - Event/meeting card
  - `WorkHourCard` - Work hours card

### ✅ Listeners (`calendar_listeners.dart`)
- `EventDetailsListener` - Listens for event selection and shows dialog
- `HourDetailsListener` - Listens for work hour selection and shows dialog

### ✅ Utilities (`calendar_utils.dart`)
Helper functions for:
- Date/time formatting
- User name/initial extraction
- Meeting user extraction

### ✅ Helpers (`calendar_helpers.dart`)
- `CellItem` - Helper class for combining meetings and work hours
- `CellItemType` - Enum for cell item types

## Usage

All sections are imported and used in the main `calendar_screen.dart`:

```dart
import 'package:firefox_calendar/features/calendar/view/sections/calendar_filters.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_listeners.dart';
import 'package:firefox_calendar/features/calendar/view/sections/calendar_states.dart';
```

## Remaining Sections to Extract

The following sections are still in `calendar_screen.dart` and can be extracted in future refactoring:

1. **View Sections:**
   - Week view content
   - Day view content
   - Month view content

2. **Header Sections:**
   - Week grid header (SliverPersistentHeaderDelegate)
   - Day grid header (SliverPersistentHeaderDelegate)

3. **Grid Content Sections:**
   - Week time grid
   - Day time grid
   - Timeline grid
   - User timeline grid

4. **Cell Components:**
   - Cell content widget
   - Day date item widget

5. **Helper Classes:**
   - `_WeekGridHeaderDelegate`
   - `_DayGridHeaderDelegate`

## Benefits

- ✅ Better code organization
- ✅ Improved readability
- ✅ Easier maintenance
- ✅ Reusable components
- ✅ Separation of concerns
- ✅ Reduced file size (main file reduced from ~3507 lines)

