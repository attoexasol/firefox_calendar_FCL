# Work Hours Dashboard Implementation

## Overview

A Work Hours Dashboard screen that displays work hours summary in card format with Day, Week, and Month filters. The implementation fetches all user hours records from the API and filters on the frontend for the logged-in user.

## Implementation Details

### 1. API Service Method

**File:** `lib/services/auth_service.dart`

**Method:** `getAllUserHours()`

- **Endpoint:** `GET /api/all/user_hours`
- **Purpose:** Fetches ALL user hours records (for all users)
- **Returns:** Array of work hour records
- **Note:** Frontend filters by user ID and status

**Key Features:**
- Only sends `api_token` as query parameter (no range/date filtering)
- Returns all records for frontend filtering
- Comprehensive error handling and logging

### 2. Controller

**File:** `lib/features/dashboard/controller/work_hours_dashboard_controller.dart`

**Class:** `WorkHoursDashboardController`

**Responsibilities:**
- Fetches all user hours from API
- Filters records for logged-in user only
- Filters by status = "approved" only
- Calculates totals for Day/Week/Month
- Handles date parsing and timezone
- Manages loading and error states

**Key Methods:**

- `fetchAllUserHours()` - Fetches all records from API
- `_getFilteredWorkHours()` - Filters by user ID and status
- `_calculateTotals()` - Calculates Day/Week/Month totals
- `_parseWorkDate()` - Parses work_date with timezone handling
- `_parseTotalHours()` - Parses total_hours as numeric value
- `_isToday()`, `_isInCurrentWeek()`, `_isInCurrentMonth()` - Date range checks

**Observable State:**
- `isLoading` - Loading state
- `allWorkHours` - All records from API
- `hoursToday` - Total hours for today
- `hoursThisWeek` - Total hours for current week
- `hoursThisMonth` - Total hours for current month
- `errorMessage` - Error message if any

### 3. Widget

**File:** `lib/features/dashboard/widgets/work_hours_dashboard_cards.dart`

**Widget:** `WorkHoursDashboardCards`

**Features:**
- Displays three cards: Today, This Week, This Month
- Shows loading state while fetching
- Shows error state with retry button
- Refresh button to reload data
- Clean, card-based UI design
- Responsive layout

**Card Design:**
- Icon with color coding
- Title (Today/This Week/This Month)
- Total hours display (formatted)
- "Total hours" subtitle
- Dark/light theme support

### 4. Integration

**Files Modified:**
- `lib/app/bindings/initial_binding.dart` - Registered controller
- `lib/features/dashboard/view/dashbord_screen.dart` - Added widget to dashboard

## Data Flow

```
1. User opens Dashboard
   ↓
2. WorkHoursDashboardController.onInit() called
   ↓
3. fetchAllUserHours() called
   ↓
4. API: GET /api/all/user_hours (with api_token only)
   ↓
5. Response: Array of all users' work hours records
   ↓
6. Frontend filtering:
   - Filter by user.id (logged-in user)
   - Filter by status = "approved"
   ↓
7. Calculate totals:
   - Today: Sum total_hours for today's records
   - This Week: Sum total_hours for current week (Mon-Sun)
   - This Month: Sum total_hours for current month
   ↓
8. Display in cards via WorkHoursDashboardCards widget
```

## Filtering Logic

### User Filtering
- Extracts user ID from storage (`userId`)
- Matches against `user.id` or `user_id` in API response
- Handles both nested `user.id` and direct `user_id` structures

### Status Filtering
- Only includes records where `status = "approved"` (case-insensitive)
- Ignores "pending" and "rejected" records

### Date Range Calculations

**Today:**
- Compares work_date year, month, and day with current date

**This Week:**
- Calculates Monday of current week
- Calculates Sunday of current week
- Includes records where work_date is within Monday-Sunday range (inclusive)

**This Month:**
- Compares work_date year and month with current year and month

## Date Parsing

**Handles Multiple Formats:**
- `YYYY-MM-DD` (e.g., "2025-01-13")
- `YYYY-MM-DD HH:MM:SS` (e.g., "2025-01-13 09:00:00")
- Full DateTime strings

**Timezone Handling:**
- Parses dates as local DateTime
- Compares dates using year/month/day only (ignores time)
- Handles timezone differences by using date-only comparisons

## Total Hours Calculation

**Parsing:**
- Handles `double`, `int`, and `String` types
- Converts to `double` for calculations
- Defaults to `0.0` if parsing fails

**Summing:**
- Sums `total_hours` field from filtered records
- Uses `double` precision for accurate calculations
- Formats display: "8.5 hrs" or "8 hrs" (no decimal if whole number)

## UI Features

### Loading State
- Shows circular progress indicator
- Centered in card container

### Error State
- Shows error icon and message
- Provides retry button
- Styled with error colors

### Success State
- Three cards in a row (responsive)
- Each card shows:
  - Icon (color-coded)
  - Title
  - Total hours (large, bold)
  - "Total hours" subtitle
- Refresh button at bottom

### Theme Support
- Light and dark theme
- Uses AppColors for consistent styling
- Adapts to system theme

## Usage

The widget is automatically displayed on the Dashboard screen. To use it separately:

```dart
import 'package:firefox_calendar/features/dashboard/widgets/work_hours_dashboard_cards.dart';

// In your widget tree:
WorkHoursDashboardCards()
```

## API Response Format

**Expected API Response:**
```json
{
  "status": true,
  "message": "Success",
  "data": [
    {
      "id": 1,
      "work_date": "2025-01-13",
      "login_time": "2025-01-13 09:00:00",
      "logout_time": "2025-01-13 18:00:00",
      "total_hours": "8.0",
      "status": "approved",
      "user": {
        "id": 123
      }
    }
  ]
}
```

## Key Features

✅ **Frontend Filtering** - Filters by user ID and status on frontend  
✅ **Approved Only** - Only shows status = "approved" records  
✅ **Date Range Calculations** - Accurate Day/Week/Month calculations  
✅ **Timezone Handling** - Handles date parsing with timezone considerations  
✅ **Clean Architecture** - Separated concerns (Service, Controller, Widget)  
✅ **Error Handling** - Comprehensive error handling and user feedback  
✅ **Loading States** - Proper loading indicators  
✅ **Theme Support** - Light and dark theme support  
✅ **Reusable** - Clean, reusable code structure  

## Testing Checklist

- [ ] Verify API returns all user hours records
- [ ] Verify filtering by logged-in user ID works
- [ ] Verify only "approved" records are shown
- [ ] Verify today's total is correct
- [ ] Verify this week's total is correct (Mon-Sun)
- [ ] Verify this month's total is correct
- [ ] Verify date parsing handles different formats
- [ ] Verify timezone handling works correctly
- [ ] Verify loading state displays
- [ ] Verify error state displays with retry
- [ ] Verify refresh button works
- [ ] Verify UI displays correctly in light/dark theme

## Notes

- The API endpoint returns ALL users' records - filtering is done on frontend
- Only "approved" status records are included in calculations
- Date comparisons use date-only (ignores time component)
- Week calculation uses Monday-Sunday range
- Total hours are summed from `total_hours` field (numeric value)

---

**Implementation Date:** January 13, 2025  
**Status:** ✅ Complete

