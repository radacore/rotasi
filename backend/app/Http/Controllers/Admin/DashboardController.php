<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BpRecord;
use App\Models\Patient;
use App\Models\SymptomCheck;
use App\Models\SyncLog;

class DashboardController extends Controller
{
    public function index()
    {
        $syncedPatients = Patient::count();
        $riskMedium = Patient::where('risk_level', 'medium')->count();
        $riskHigh = Patient::where('risk_level', 'high')->count();
        $bpAlerts = BpRecord::whereIn('status_color', ['yellow', 'orange', 'red'])->count();
        $bpPatientIds = BpRecord::whereIn('status_color', ['yellow', 'orange', 'red'])
            ->distinct()->pluck('patient_uuid');
        $symptomAlerts = SymptomCheck::where(function ($q) {
            $q->where('headache', 1)->orWhere('blurred_vision', 1)
                ->orWhere('epigastric_pain', 1)->orWhere('shortness_of_breath', 1);
        })->count();
        $symptomPatientIds = SymptomCheck::where(function ($q) {
            $q->where('headache', 1)->orWhere('blurred_vision', 1)
                ->orWhere('epigastric_pain', 1)->orWhere('shortness_of_breath', 1);
        })->distinct()->pluck('patient_uuid');
        $sync7d = SyncLog::where('synced_at', '>=', now()->subDays(7))->count();
        $alertIds = collect($bpPatientIds)->merge($symptomPatientIds)->unique()->values();
        $attentionPatients = Patient::query()
            ->where(fn ($q) => $q->whereIn('risk_level', ['medium', 'high'])->orWhereIn('uuid', $alertIds))
            ->orderByRaw("CASE risk_level WHEN 'high' THEN 0 WHEN 'medium' THEN 1 WHEN 'low' THEN 2 ELSE 3 END")
            ->orderByDesc('updated_at')->limit(5)->get()
            ->map(fn (Patient $p) => [
                'uuid' => $p->uuid, 'name' => $p->name, 'age' => $p->age,
                'gestational_weeks' => $p->gestational_weeks, 'risk_level' => $p->risk_level,
                'has_bp_alert' => $bpPatientIds->contains($p->uuid),
                'has_symptom_alert' => $symptomPatientIds->contains($p->uuid),
                'updated_at' => $p->updated_at?->toDateTimeString(),
            ])->all();
        $recentSyncs = SyncLog::orderByDesc('id')->limit(10)->get(['id', 'device_uuid', 'status', 'records_count', 'synced_at']);

        return $this->ok([
            'stats' => [
                'synced_patients' => $syncedPatients,
                'risk_medium' => $riskMedium, 'risk_high' => $riskHigh,
                'risk_at_risk' => $riskMedium + $riskHigh,
                'bp_alerts' => $bpAlerts, 'bp_patients' => $bpPatientIds->count(),
                'symptom_alerts' => $symptomAlerts, 'symptom_patients' => $symptomPatientIds->count(),
                'sync_7d' => $sync7d,
                'active_booklet_version' => 0, 'booklet_releases' => 0, 'apk_releases' => 0,
                'sync_count_24h' => $sync7d,
            ],
            'attention_patients' => $attentionPatients,
            'recent_syncs' => $recentSyncs->map(fn ($s) => [
                'id' => $s->id, 'device_uuid' => $s->device_uuid, 'status' => $s->status,
                'records_count' => $s->records_count, 'synced_at' => $s->synced_at?->toDateTimeString(),
            ])->all(),
        ], 'Data dashboard');
    }
}
