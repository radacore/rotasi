<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SyncLog;
use Illuminate\Http\Request;

class WebSyncLogController extends Controller
{
    public function index(Request $request)
    {
        $query = SyncLog::query()
            ->leftJoin('patients', 'patients.uuid', '=', 'sync_logs.patient_uuid')
            ->select('sync_logs.*', 'patients.name as patient_name')
            ->orderByDesc('sync_logs.id');

        if ($status = $request->query('status')) {
            $query->where('sync_logs.status', $status);
        }

        if ($search = trim((string) $request->query('search'))) {
            $query->where(function ($q) use ($search) {
                $q->where('sync_logs.device_uuid', 'like', "%{$search}%")
                    ->orWhere('patients.name', 'like', "%{$search}%");
            });
        }

        $logs = $query->paginate(20)->withQueryString();

        $logs->getCollection()->transform(fn ($log) => [
            'id' => $log->id,
            'device_uuid' => $log->device_uuid,
            'patient_name' => $log->patient_name,
            'patient_uuid' => $log->patient_uuid,
            'status' => $log->status,
            'records_count' => $log->records_count,
            'synced_at' => $log->synced_at?->toDateTimeString(),
        ]);

        return inertia('SyncLogs/Index', [
            'logs' => $logs,
            'filters' => ['status' => $status, 'search' => $request->query('search', '')],
        ]);
    }
}
