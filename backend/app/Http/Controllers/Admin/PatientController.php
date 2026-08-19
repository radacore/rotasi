<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BpRecord;
use App\Models\Patient;
use App\Models\SyncLog;
use Illuminate\Http\Request;

class PatientController extends Controller
{
    public function index(Request $request)
    {
        $query = Patient::query()->orderByDesc('updated_at');

        if ($risk = $request->query('risk')) {
            $query->where('risk_level', $risk);
        }

        $perPage = min((int) $request->query('per_page', 20), 100);
        $items = $query->paginate($perPage);

        $data = $items->map(function (Patient $p) {
            $latestBp = $p->bpRecords()->orderByDesc('measured_at')->first();

            return [
                'patient_uuid' => $p->uuid,
                'name' => $p->name,
                'age' => $p->age,
                'risk_level' => $p->risk_level,
                'bp_count' => $p->bpRecords()->count(),
                'latest_bp' => $latestBp ? [
                    'avg_systolic' => $latestBp->avg_systolic,
                    'avg_diastolic' => $latestBp->avg_diastolic,
                    'status_color' => $latestBp->status_color,
                ] : null,
                'last_synced_at' => $p->updated_at?->toDateTimeString(),
            ];
        })->all();

        return response()->json([
            'success' => true,
            'data' => $data,
            'message' => 'Daftar pasien',
            'pagination' => [
                'current_page' => $items->currentPage(),
                'per_page' => $items->perPage(),
                'total' => $items->total(),
                'last_page' => $items->lastPage(),
                'from' => $items->firstItem(),
                'to' => $items->lastItem(),
            ],
        ]);
    }

    public function show(string $patientUuid)
    {
        $patient = Patient::with(['bpRecords' => fn ($q) => $q->orderByDesc('measured_at')])
            ->find($patientUuid);

        if (! $patient) {
            return $this->fail('Pasien tidak ditemukan', 404, 'not_found');
        }

        $syncLogs = SyncLog::where('patient_uuid', $patientUuid)
            ->orderByDesc('id')
            ->limit(20)
            ->get(['id', 'status', 'records_count', 'synced_at']);

        return $this->ok([
            'patient_uuid' => $patient->uuid,
            'profile' => $patient->toArray(),
            'bp_records' => $patient->bpRecords->map(fn (BpRecord $b) => $b->toArray())->all(),
            'sync_logs' => $syncLogs->map(fn ($s) => [
                'id' => $s->id,
                'status' => $s->status,
                'records_count' => $s->records_count,
                'synced_at' => $s->synced_at?->toDateTimeString(),
            ])->all(),
        ], 'Detail pasien');
    }
}
