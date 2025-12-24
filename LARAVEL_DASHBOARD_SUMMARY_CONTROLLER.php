<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserHours;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * Dashboard Summary Controller
 * 
 * IMPORTANT RULES:
 * - hours_today and hours_this_week MUST be calculated ONLY from APPROVED work hours
 * - Pending work hours must NEVER be included in totals
 * - Auto-approval runs BEFORE calculating totals
 * - Frontend must NOT calculate totals manually - trust backend calculation
 */
class DashboardSummaryController extends Controller
{
    /**
     * Get Dashboard Summary
     * 
     * Endpoint: GET /api/dashboard/summary
     * 
     * Response:
     * {
     *   "status": true,
     *   "data": {
     *     "hours_today": 7.5,        // APPROVED hours only
     *     "hours_this_week": 37.5,   // APPROVED hours only
     *     "events_this_week": 8,      // Informational
     *     "leave_this_week": 2,       // Informational
     *     "has_pending_hours": true   // Warning flag
     *   }
     * }
     * 
     * CRITICAL: Auto-approval runs FIRST, then calculates approved-only totals
     */
    public function getSummary(Request $request)
    {
        try {
            // Get authenticated user
            $user = Auth::user();
            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized',
                ], 401);
            }

            // STEP 1: AUTO-APPROVE eligible entries
            // This runs BEFORE calculating totals to ensure accurate approved hours
            $this->autoApproveEligibleEntries($user->id);

            // STEP 2: Calculate hours_today (APPROVED ONLY)
            $hoursToday = $this->calculateApprovedHoursToday($user->id);

            // STEP 3: Calculate hours_this_week (APPROVED ONLY)
            $hoursThisWeek = $this->calculateApprovedHoursThisWeek($user->id);

            // STEP 4: Check for pending hours (for warning indicator)
            $hasPendingHours = $this->hasPendingHours($user->id);

            // STEP 5: Get events and leave counts (informational)
            $eventsThisWeek = $this->getEventsThisWeek($user->id);
            $leaveThisWeek = $this->getLeaveThisWeek($user->id);

            return response()->json([
                'status' => true,
                'message' => 'Dashboard summary fetched successfully',
                'data' => [
                    'hours_today' => round($hoursToday, 1),           // APPROVED ONLY
                    'hours_this_week' => round($hoursThisWeek, 1),   // APPROVED ONLY
                    'events_this_week' => $eventsThisWeek,
                    'leave_this_week' => $leaveThisWeek,
                    'has_pending_hours' => $hasPendingHours,
                ],
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to fetch dashboard summary: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Auto-approve eligible entries
     * 
     * SAFE AUTO-APPROVAL RULES:
     * - Only approve entries with BOTH login_time AND logout_time
     * - Only approve entries with status = "pending"
     * - Do NOT approve incomplete rows (missing login_time or logout_time)
     * - Do NOT approve future entries (date > today)
     * - Do NOT approve entries without logout_time
     * 
     * This runs INSIDE the dashboard summary API to ensure
     * totals are calculated from the latest approved entries.
     * 
     * ALTERNATIVE: Can also run via scheduled job (cron) every hour/day
     */
    /**
     * Auto-approve eligible entries
     * 
     * AUTO-APPROVAL RULES (NO ADMIN):
     * - Frontend must NEVER set status = approved
     * - Backend automatically approves when ALL conditions are met:
     *   1. status = "pending"
     *   2. login_time IS NOT NULL
     *   3. logout_time IS NOT NULL
     *   4. date <= today (safety: no future entries)
     * 
     * This runs INSIDE GET /api/dashboard/summary
     * NOT from frontend
     */
    private function autoApproveEligibleEntries($userId)
    {
        // Auto-approve entries that meet ALL criteria:
        // 1. user_id matches
        // 2. status = "pending"
        // 3. login_time IS NOT NULL
        // 4. logout_time IS NOT NULL
        // 5. date <= today (safety: no future entries)
        // 
        // Matches user's exact Laravel logic example
        $updated = UserHours::where('user_id', $userId)
            ->where('status', 'pending')
            ->whereNotNull('login_time')
            ->whereNotNull('logout_time')
            ->whereDate('date', '<=', now()) // Safety: no future entries
            ->update(['status' => 'approved']);

        if ($updated > 0) {
            \Log::info("Auto-approved {$updated} work hours entries for user {$userId}");
        }

        return $updated;
    }

    /**
     * Calculate approved hours for today
     * 
     * CRITICAL: Only includes APPROVED hours
     * Pending hours are EXCLUDED from this calculation
     * 
     * @return float Total approved hours for today
     */
    private function calculateApprovedHoursToday($userId)
    {
        $today = Carbon::today()->format('Y-m-d');

        // Sum total_hours from APPROVED entries only
        // Pending entries are EXCLUDED
        $totalHours = UserHours::where('user_id', $userId)
            ->where('status', 'approved')  // CRITICAL: Only approved
            ->whereDate('date', $today)
            ->sum('total_hours');

        return $totalHours ?? 0.0;
    }

    /**
     * Calculate approved hours for this week
     * 
     * CRITICAL: Only includes APPROVED hours
     * Pending hours are EXCLUDED from this calculation
     * 
     * Week starts on Monday and ends on Sunday
     * 
     * @return float Total approved hours for this week
     */
    private function calculateApprovedHoursThisWeek($userId)
    {
        // Get current week start (Monday) and end (Sunday)
        $weekStart = Carbon::now()->startOfWeek(Carbon::MONDAY)->format('Y-m-d');
        $weekEnd = Carbon::now()->endOfWeek(Carbon::SUNDAY)->format('Y-m-d');

        // Sum total_hours from APPROVED entries only
        // Pending entries are EXCLUDED
        $totalHours = UserHours::where('user_id', $userId)
            ->where('status', 'approved')  // CRITICAL: Only approved
            ->whereBetween('date', [$weekStart, $weekEnd])
            ->sum('total_hours');

        return $totalHours ?? 0.0;
    }

    /**
     * Check if user has any pending hours
     * 
     * Used for warning indicator in dashboard UI
     * 
     * @return bool True if any pending entries exist
     */
    private function hasPendingHours($userId)
    {
        return UserHours::where('user_id', $userId)
            ->where('status', 'pending')
            ->exists();
    }

    /**
     * Get events count for this week
     * 
     * Informational only - not used in hours calculation
     * 
     * @return int Count of events this week
     */
    private function getEventsThisWeek($userId)
    {
        // TODO: Implement events count logic
        // This is informational only
        return 0;
    }

    /**
     * Get leave count for this week
     * 
     * Informational only - not used in hours calculation
     * 
     * @return int Count of leave days this week
     */
    private function getLeaveThisWeek($userId)
    {
        // TODO: Implement leave count logic
        // This is informational only
        return 0;
    }
}
