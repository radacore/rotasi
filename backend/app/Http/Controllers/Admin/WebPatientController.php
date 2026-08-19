<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BpRecord;
use App\Models\Patient;
use App\Models\SyncLog;
use Illuminate\Http\Request;

class WebPatientController extends Controller
{
    public function index(Request $request)
    {
        $query = Patient::query()->orderByDesc('updated_at');

        if ($risk = $request->query('risk')) {
            $query->where('risk_level', $risk);
        }

        $patients = $query->paginate(15)->withQueryString();

        $patients->getCollection()->transform(function (Patient $p) {
            $latestBp = $p->bpRecords()->orderByDesc('measured_at')->first();

            return [
                'patient_uuid' => $p->uuid,
                'name' => $p->name,
                'age' => $p->age,
                'gestational_weeks' => $p->gestational_weeks,
                'risk_level' => $p->risk_level,
                'bp_count' => $p->bpRecords()->count(),
                'latest_bp' => $latestBp ? [
                    'avg_systolic' => $latestBp->avg_systolic,
                    'avg_diastolic' => $latestBp->avg_diastolic,
                    'status_color' => $latestBp->status_color,
                ] : null,
                'last_synced_at' => $p->updated_at?->toDateTimeString(),
            ];
        });

        return inertia('Patients/Index', [
            'patients' => $patients,
            'filters' => ['risk' => $risk],
        ]);
    }

    public function show(string $patientUuid)
    {
        $patient = Patient::with([
            'bpRecords' => fn ($q) => $q->orderByDesc('measured_at')->limit(30),
            'symptomChecks' => fn ($q) => $q->orderByDesc('checked_at')->limit(10),
            'kickCounts' => fn ($q) => $q->orderByDesc('started_at')->limit(10),
            'ancChecks' => fn ($q) => $q->orderByDesc('visited_at')->limit(10),
        ])->find($patientUuid);

        if (! $patient) {
            abort(404);
        }

        $syncLogs = SyncLog::where('patient_uuid', $patientUuid)
            ->orderByDesc('id')
            ->limit(20)
            ->get(['id', 'status', 'records_count', 'synced_at']);

        return inertia('Patients/Show', [
            'patient' => [
                'uuid' => $patient->uuid,
                'name' => $patient->name,
                'age' => $patient->age,
                'height_cm' => $patient->height_cm,
                'weight_kg' => $patient->weight_kg,
                'gestational_weeks' => $patient->gestational_weeks,
                'due_date' => $patient->due_date?->toDateString(),
                'last_systolic' => $patient->last_systolic,
                'last_diastolic' => $patient->last_diastolic,
                'history_type' => $patient->history_type,
                'risk_level' => $patient->risk_level,
                'phone' => $patient->phone,
                'device_uuid' => $patient->device_uuid,
            ],
            'counts' => [
                'bp' => $patient->bpRecords()->count(),
                'symptom' => $patient->symptomChecks()->count(),
                'kick' => $patient->kickCounts()->count(),
                'anc' => $patient->ancChecks()->count(),
            ],
            'bp_records' => $patient->bpRecords->map(fn (BpRecord $b) => [
                'uuid' => $b->uuid,
                'measured_at' => $b->measured_at?->toDateTimeString(),
                'session_code' => $b->session_code,
                'systolic_1' => $b->systolic_1,
                'diastolic_1' => $b->diastolic_1,
                'systolic_2' => $b->systolic_2,
                'diastolic_2' => $b->diastolic_2,
                'avg_systolic' => $b->avg_systolic,
                'avg_diastolic' => $b->avg_diastolic,
                'status_color' => $b->status_color,
            ])->all(),
            'symptom_checks' => $patient->symptomChecks->map(fn ($s) => [
                'uuid' => $s->uuid,
                'checked_at' => $s->checked_at?->toDateTimeString(),
                'headache' => $s->headache,
                'blurred_vision' => $s->blurred_vision,
                'epigastric_pain' => $s->epigastric_pain,
                'shortness_of_breath' => $s->shortness_of_breath,
            ])->all(),
            'kick_counts' => $patient->kickCounts->map(fn ($k) => [
                'uuid' => $k->uuid,
                'started_at' => $k->started_at?->toDateTimeString(),
                'kick_count' => $k->kick_count,
                'is_active' => $k->is_active,
            ])->all(),
            'anc_checks' => $patient->ancChecks->map(fn ($a) => [
                'uuid' => $a->uuid,
                'visited_at' => $a->visited_at?->toDateString(),
                't_items_count' => count($a->t_items ?? []),
            ])->all(),
            'sync_logs' => $syncLogs->map(fn ($s) => [
                'id' => $s->id,
                'status' => $s->status,
                'records_count' => $s->records_count,
                'synced_at' => $s->synced_at?->toDateTimeString(),
            ])->all(),
        ]);
    }
}
