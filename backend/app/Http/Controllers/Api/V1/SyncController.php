<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\BpRecord;
use App\Models\Device;
use App\Models\KickCount;
use App\Models\Patient;
use App\Models\SyncLog;
use App\Models\SymptomCheck;
use App\Models\AncCheck;
use Illuminate\Http\Request;

class SyncController extends Controller
{
    private function device(Request $request): Device
    {
        /** @var Device $device */
        return $request->user();
    }

    private function ensurePatientOwned(Device $device, ?string $patientUuid): bool
    {
        if (! $patientUuid) {
            return false;
        }

        return Patient::where('uuid', $patientUuid)
            ->where('device_uuid', $device->device_uuid)
            ->exists();
    }

    private function upsertBp(array $r): bool
    {
        if (BpRecord::where('uuid', $r['uuid'])->exists()) {
            return false;
        }

        BpRecord::create($r);
        $this->promoteUnknownRisk($r['patient_uuid'], $r['avg_systolic'], $r['avg_diastolic']);

        return true;
    }

    private function promoteUnknownRisk(string $patientUuid, int $avgSys, int $avgDia): void
    {
        $patient = Patient::find($patientUuid);
        if (! $patient || $patient->risk_level !== 'unknown') return;
        $bmi = null;
        if ($patient->height_cm && (float) $patient->height_cm > 0) {
            $h = (float) $patient->height_cm / 100;
            $bmi = (float) $patient->weight_kg / ($h * $h);
        }
        $high = ($patient->history_type === 'prior_preeclampsia') || ($patient->age >= 40) || ($bmi !== null && $bmi >= 35);
        $med = ($patient->history_type === 'hypertension') || ($patient->history_type === 'family') || ($patient->age > 35) || ($bmi !== null && $bmi > 30);
        $level = $high ? 'high' : ($med ? 'medium' : 'low');
        $patient->update(['last_systolic' => $avgSys, 'last_diastolic' => $avgDia, 'risk_level' => $level]);
    }

    private function upsertSymptom(array $r): bool
    {
        if (SymptomCheck::where('uuid', $r['uuid'])->exists()) {
            return false;
        }

        SymptomCheck::create($r);

        return true;
    }

    private function upsertKick(array $r): bool
    {
        if (KickCount::where('uuid', $r['uuid'])->exists()) {
            return false;
        }

        KickCount::create($r);

        return true;
    }

    private function upsertAnc(array $r): bool
    {
        if (AncCheck::where('uuid', $r['uuid'])->exists()) {
            return false;
        }

        AncCheck::create($r);

        return true;
    }

    public function sync(Request $request)
    {
        $device = $this->device($request);

        $data = $request->validate([
            'patient_uuid' => ['required', 'string', 'size:36'],
            'records.bp_records' => ['nullable', 'array'],
            'records.bp_records.*.uuid' => ['required', 'string', 'size:36'],
            'records.bp_records.*.measured_at' => ['required', 'date'],
            'records.bp_records.*.session_code' => ['required', 'in:pagi,sore,anc'],
            'records.bp_records.*.systolic_1' => ['required', 'integer', 'min:50', 'max:180'],
            'records.bp_records.*.diastolic_1' => ['required', 'integer', 'min:30', 'max:120'],
            'records.bp_records.*.systolic_2' => ['required', 'integer', 'min:50', 'max:180'],
            'records.bp_records.*.diastolic_2' => ['required', 'integer', 'min:30', 'max:120'],
            'records.bp_records.*.avg_systolic' => ['required', 'integer', 'min:50', 'max:180'],
            'records.bp_records.*.avg_diastolic' => ['required', 'integer', 'min:30', 'max:120'],
            'records.bp_records.*.status_color' => ['required', 'in:green,yellow,orange,red'],
            'records.symptom_checks' => ['nullable', 'array'],
            'records.symptom_checks.*.uuid' => ['required', 'string', 'size:36'],
            'records.symptom_checks.*.checked_at' => ['required', 'date'],
            'records.symptom_checks.*.headache' => ['boolean'],
            'records.symptom_checks.*.blurred_vision' => ['boolean'],
            'records.symptom_checks.*.epigastric_pain' => ['boolean'],
            'records.symptom_checks.*.shortness_of_breath' => ['boolean'],
            'records.kick_counts' => ['nullable', 'array'],
            'records.kick_counts.*.uuid' => ['required', 'string', 'size:36'],
            'records.kick_counts.*.started_at' => ['required', 'date'],
            'records.kick_counts.*.ended_at' => ['nullable', 'date'],
            'records.kick_counts.*.kick_count' => ['nullable', 'integer', 'min:0'],
            'records.kick_counts.*.is_active' => ['nullable', 'boolean'],
            'records.anc_checks' => ['nullable', 'array'],
            'records.anc_checks.*.uuid' => ['required', 'string', 'size:36'],
            'records.anc_checks.*.visited_at' => ['required', 'date'],
            'records.anc_checks.*.t_items' => ['required', 'array'],
        ]);

        if (! $this->ensurePatientOwned($device, $data['patient_uuid'])) {
            return $this->fail('Pasien tidak ditemukan untuk perangkat ini', 422, 'patient_mismatch');
        }

        $patientUuid = $data['patient_uuid'];
        $acceptedBp = $acceptedSymptoms = $acceptedKicks = $acceptedAnc = [];
        $duplicates = 0;

        foreach ($data['records']['bp_records'] ?? [] as $r) {
            $r['patient_uuid'] = $patientUuid;
            if ($this->upsertBp($r)) {
                $acceptedBp[] = $r['uuid'];
            } else {
                $duplicates++;
            }
        }

        foreach ($data['records']['symptom_checks'] ?? [] as $r) {
            $r['patient_uuid'] = $patientUuid;
            if ($this->upsertSymptom($r)) {
                $acceptedSymptoms[] = $r['uuid'];
            } else {
                $duplicates++;
            }
        }

        foreach ($data['records']['kick_counts'] ?? [] as $r) {
            $r['patient_uuid'] = $patientUuid;
            if ($this->upsertKick($r)) {
                $acceptedKicks[] = $r['uuid'];
            } else {
                $duplicates++;
            }
        }

        foreach ($data['records']['anc_checks'] ?? [] as $r) {
            $r['patient_uuid'] = $patientUuid;
            if ($this->upsertAnc($r)) {
                $acceptedAnc[] = $r['uuid'];
            } else {
                $duplicates++;
            }
        }

        $total = count($acceptedBp) + count($acceptedSymptoms) + count($acceptedKicks) + count($acceptedAnc);

        SyncLog::create([
            'device_uuid' => $device->device_uuid,
            'patient_uuid' => $patientUuid,
            'status' => 'success',
            'records_count' => $total,
            'synced_at' => now(),
        ]);

        return $this->ok([
            'accepted_bp' => $acceptedBp,
            'accepted_symptoms' => $acceptedSymptoms,
            'accepted_kicks' => $acceptedKicks,
            'accepted_anc' => $acceptedAnc,
            'duplicates_skipped' => $duplicates,
        ], "Sinkronisasi berhasil, {$total} record diproses");
    }

    public function bp(Request $request)
    {
        $device = $this->device($request);
        $data = $request->validate([
            'patient_uuid' => ['required', 'string', 'size:36'],
            'uuid' => ['required', 'string', 'size:36'],
            'measured_at' => ['required', 'date'],
            'session_code' => ['required', 'in:pagi,sore,anc'],
            'systolic_1' => ['required', 'integer', 'min:50', 'max:180'],
            'diastolic_1' => ['required', 'integer', 'min:30', 'max:120'],
            'systolic_2' => ['required', 'integer', 'min:50', 'max:180'],
            'diastolic_2' => ['required', 'integer', 'min:30', 'max:120'],
            'avg_systolic' => ['required', 'integer', 'min:50', 'max:180'],
            'avg_diastolic' => ['required', 'integer', 'min:30', 'max:120'],
            'status_color' => ['required', 'in:green,yellow,orange,red'],
        ]);

        if (! $this->ensurePatientOwned($device, $data['patient_uuid'])) {
            return $this->fail('Pasien tidak ditemukan untuk perangkat ini', 422, 'patient_mismatch');
        }

        if (BpRecord::where('uuid', $data['uuid'])->exists()) {
            return $this->ok(['uuid' => $data['uuid']], 'Duplikat diabaikan', 200);
        }

        $this->upsertBp($data);
        SyncLog::create([
            'device_uuid' => $device->device_uuid,
            'patient_uuid' => $data['patient_uuid'],
            'status' => 'success',
            'records_count' => 1,
            'synced_at' => now(),
        ]);

        return $this->ok(['uuid' => $data['uuid']], 'Record tekanan darah disimpan', 201);
    }

    public function symptom(Request $request)
    {
        $device = $this->device($request);
        $data = $request->validate([
            'patient_uuid' => ['required', 'string', 'size:36'],
            'uuid' => ['required', 'string', 'size:36'],
            'checked_at' => ['required', 'date'],
            'headache' => ['boolean'],
            'blurred_vision' => ['boolean'],
            'epigastric_pain' => ['boolean'],
            'shortness_of_breath' => ['boolean'],
        ]);

        if (! $this->ensurePatientOwned($device, $data['patient_uuid'])) {
            return $this->fail('Pasien tidak ditemukan untuk perangkat ini', 422, 'patient_mismatch');
        }

        if (SymptomCheck::where('uuid', $data['uuid'])->exists()) {
            return $this->ok(['uuid' => $data['uuid']], 'Duplikat diabaikan', 200);
        }

        $this->upsertSymptom($data);
        SyncLog::create([
            'device_uuid' => $device->device_uuid,
            'patient_uuid' => $data['patient_uuid'],
            'status' => 'success',
            'records_count' => 1,
            'synced_at' => now(),
        ]);

        return $this->ok(['uuid' => $data['uuid']], 'Ceklis gejala disimpan', 201);
    }

    public function kick(Request $request)
    {
        $device = $this->device($request);
        $data = $request->validate([
            'patient_uuid' => ['required', 'string', 'size:36'],
            'uuid' => ['required', 'string', 'size:36'],
            'started_at' => ['required', 'date'],
            'ended_at' => ['nullable', 'date'],
            'kick_count' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        if (! $this->ensurePatientOwned($device, $data['patient_uuid'])) {
            return $this->fail('Pasien tidak ditemukan untuk perangkat ini', 422, 'patient_mismatch');
        }

        if (KickCount::where('uuid', $data['uuid'])->exists()) {
            return $this->ok(['uuid' => $data['uuid']], 'Duplikat diabaikan', 200);
        }

        $this->upsertKick($data);
        SyncLog::create([
            'device_uuid' => $device->device_uuid,
            'patient_uuid' => $data['patient_uuid'],
            'status' => 'success',
            'records_count' => 1,
            'synced_at' => now(),
        ]);

        return $this->ok(['uuid' => $data['uuid']], 'Hitungan gerakan janin disimpan', 201);
    }

    public function anc(Request $request)
    {
        $device = $this->device($request);
        $data = $request->validate([
            'patient_uuid' => ['required', 'string', 'size:36'],
            'uuid' => ['required', 'string', 'size:36'],
            'visited_at' => ['required', 'date'],
            't_items' => ['required', 'array'],
        ]);

        if (! $this->ensurePatientOwned($device, $data['patient_uuid'])) {
            return $this->fail('Pasien tidak ditemukan untuk perangkat ini', 422, 'patient_mismatch');
        }

        if (AncCheck::where('uuid', $data['uuid'])->exists()) {
            return $this->ok(['uuid' => $data['uuid']], 'Duplikat diabaikan', 200);
        }

        $this->upsertAnc($data);
        SyncLog::create([
            'device_uuid' => $device->device_uuid,
            'patient_uuid' => $data['patient_uuid'],
            'status' => 'success',
            'records_count' => 1,
            'synced_at' => now(),
        ]);

        return $this->ok(['uuid' => $data['uuid']], 'Ceklis 10T disimpan', 201);
    }
}
