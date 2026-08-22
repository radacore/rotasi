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

        $risk = $request->query('risk');
        $search = trim((string) $request->query('search', ''));

        if ($risk) {
            $query->where('risk_level', $risk);
        }

        if ($search !== '') {
            $query->where('name', 'like', "%{$search}%");
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
            'filters' => ['risk' => $risk, 'search' => $search],
        ]);
    }

    public function destroy(string $patientUuid)
    {
        $patient = Patient::find($patientUuid);
        if (! $patient) {
            abort(404);
        }
        SyncLog::where('patient_uuid', $patientUuid)->delete();
        $patient->delete();

        return redirect()->route('patients.index')->with('success', 'Pasien dihapus.');
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

        $bmi = null;
        if ($patient->height_cm && (float) $patient->height_cm > 0) {
            $h = (float) $patient->height_cm / 100;
            $bmi = (float) $patient->weight_kg / ($h * $h);
        }

        $historyLabels = [
            'none' => 'Tidak ada',
            'hypertension' => 'Hipertensi',
            'prior_preeclampsia' => 'Pernah preeklamsia',
            'family' => 'Riwayat turunan',
        ];

        $riskFactors = [];
        if (($patient->history_type ?? 'none') !== 'none') {
            $riskFactors[] = $historyLabels[$patient->history_type] ?? $patient->history_type;
        }
        if (($patient->age ?? 0) > 35) {
            $riskFactors[] = 'Usia > 35 tahun';
        }
        if ($bmi !== null && $bmi > 30) {
            $riskFactors[] = 'IMT '.number_format($bmi, 1);
        }

        $recommendation = match ($patient->risk_level) {
            'high' => 'Risiko tinggi. Segera konsultasikan ke tenaga kesehatan untuk penanganan khusus.',
            'medium' => 'Risiko sedang. Konsultasikan dengan bidan untuk pemantauan lebih ketat.',
            'low' => 'Risiko rendah. Lanjutkan pola hidup sehat dan kontrol ANC rutin.',
            default => 'Belum ada pengukuran tensi. Lakukan pengukuran pertama untuk menilai risiko.',
        };

        return inertia('Patients/Show', [
            'patient' => [
                'uuid' => $patient->uuid,
                'name' => $patient->name,
                'age' => $patient->age,
                'height_cm' => $patient->height_cm,
                'weight_kg' => $patient->weight_kg,
                'bmi' => $bmi !== null ? round($bmi, 1) : null,
                'gestational_weeks' => $patient->gestational_weeks,
                'due_date' => $patient->due_date?->toDateString(),
                'last_systolic' => $patient->last_systolic,
                'last_diastolic' => $patient->last_diastolic,
                'history_type' => $patient->history_type,
                'history_label' => $historyLabels[$patient->history_type] ?? $patient->history_type ?? '-',
                'risk_level' => $patient->risk_level,
                'risk_factors' => $riskFactors,
                'recommendation' => $recommendation,
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
                'ended_at' => $k->ended_at?->toDateTimeString(),
                'kick_count' => $k->kick_count,
                'is_active' => $k->is_active,
            ])->all(),
            'anc_checks' => $patient->ancChecks->map(function ($a) {
                $items = $a->t_items ?? [];
                $labels = [
                    't1' => 'Berat Badan', 't2' => 'Tekanan Darah', 't3' => 'Tinggi Fundus',
                    't4' => 'Letak Janin', 't5' => 'DJJ', 't6' => 'Imunisasi TT',
                    't7' => 'Tablet Tambah Darah', 't8' => 'Pemeriksaan Lab',
                    't9' => 'Tatalaksana', 't10' => 'Konseling',
                ];
                return [
                    'uuid' => $a->uuid,
                    'visited_at' => $a->visited_at?->toDateString(),
                    't_items' => $items,
                    't_items_count' => count($items),
                    't_items_labels' => array_map(fn ($c) => $labels[$c] ?? $c, $items),
                ];
            })->all(),
            'sync_logs' => $syncLogs->map(fn ($s) => [
                'id' => $s->id,
                'status' => $s->status,
                'records_count' => $s->records_count,
                'synced_at' => $s->synced_at?->toDateTimeString(),
            ])->all(),
        ]);
    }
}
