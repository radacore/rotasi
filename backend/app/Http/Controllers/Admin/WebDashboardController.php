<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ApkRelease;
use App\Models\BookletRelease;
use App\Models\Patient;
use App\Models\SyncLog;
use Illuminate\Http\Request;

class WebDashboardController extends Controller
{
    public function index(Request $request)
    {
        $syncedPatients = Patient::query()->distinct()->count('uuid');

        $recentSyncs = SyncLog::orderByDesc('id')->limit(10)->get([
            'id', 'device_uuid', 'status', 'records_count', 'synced_at',
        ]);

        return inertia('Dashboard', [
            'stats' => [
                'active_booklet_version' => (int) BookletRelease::where('is_active', true)->value('version') ?? 0,
                'booklet_releases' => BookletRelease::count(),
                'apk_releases' => ApkRelease::count(),
                'synced_patients' => $syncedPatients,
                'sync_count_24h' => SyncLog::where('synced_at', '>=', now()->subDay())->count(),
            ],
            'recent_syncs' => $recentSyncs->map(fn ($s) => [
                'id' => $s->id,
                'device_uuid' => $s->device_uuid,
                'status' => $s->status,
                'records_count' => $s->records_count,
                'synced_at' => $s->synced_at?->toDateTimeString(),
            ])->all(),
        ]);
    }
}
