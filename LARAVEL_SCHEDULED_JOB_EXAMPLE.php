<?php

namespace App\Console\Commands;

use App\Models\UserHours;
use Carbon\Carbon;
use Illuminate\Console\Command;

/**
 * Auto-approve Work Hours Entries (Scheduled Job)
 * 
 * ALTERNATIVE to running auto-approval in dashboard summary API
 * 
 * This can be scheduled to run via Laravel's task scheduler:
 * 
 * In app/Console/Kernel.php:
 * 
 * protected function schedule(Schedule $schedule)
 * {
 *     $schedule->command('work-hours:auto-approve')->hourly();
 * }
 * 
 * Or run daily:
 * $schedule->command('work-hours:auto-approve')->daily();
 * 
 * SAFE AUTO-APPROVAL RULES:
 * - Only approve entries with BOTH login_time AND logout_time
 * - Only approve entries with status = "pending"
 * - Do NOT approve incomplete rows
 * - Do NOT approve future entries
 */
class AutoApproveWorkHours extends Command
{
    protected $signature = 'work-hours:auto-approve';
    protected $description = 'Auto-approve eligible work hours entries';

    public function handle()
    {
        $today = Carbon::today()->format('Y-m-d');

        // Auto-approve entries that meet ALL criteria:
        // 1. status = "pending"
        // 2. login_time IS NOT NULL
        // 3. logout_time IS NOT NULL
        // 4. date <= today (not future entries)
        $updated = UserHours::where('status', 'pending')
            ->whereNotNull('login_time')
            ->whereNotNull('logout_time')
            ->whereDate('date', '<=', $today) // Safety: no future entries
            ->update(['status' => 'approved']);

        $this->info("Auto-approved {$updated} work hours entries");

        return 0;
    }
}
