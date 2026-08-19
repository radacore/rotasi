<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\Patient;
use Illuminate\Http\Request;

class PatientController extends Controller
{
    private function device(Request $request): Device
    {
        /** @var Device $device */
        $device = $request->user();

        return $device;
    }

    public function upsert(Request $request)
    {
        $device = $this->device($request);

        $data = $request->validate([
            'patient_uuid' => ['required', 'string', 'size:36'],
            'name' => ['required', 'string', 'max:100'],
            'age' => ['required', 'integer', 'min:12', 'max:55'],
            'height_cm' => ['required', 'numeric', 'min:100', 'max:250'],
            'weight_kg' => ['required', 'numeric', 'min:30', 'max:200'],
            'gestational_weeks' => ['nullable', 'integer', 'min:0', 'max:45'],
            'due_date' => ['nullable', 'date'],
            'last_systolic' => ['nullable', 'integer', 'min:50', 'max:180'],
            'last_diastolic' => ['nullable', 'integer', 'min:30', 'max:120'],
            'history_type' => ['required', 'in:none,hypertension,prior_preeclampsia,family'],
            'risk_level' => ['required', 'in:low,medium,high'],
            'phone' => ['nullable', 'string', 'max:20'],
        ]);

        $data['device_uuid'] = $device->device_uuid;

        $patient = Patient::updateOrCreate(
            ['uuid' => $data['patient_uuid']],
            $data,
        );

        return $this->ok([
            'patient_uuid' => $patient->uuid,
            'risk_level' => $patient->risk_level,
            'sync_status' => 'synced',
        ], 'Profil pasien tersinkron');
    }

    public function show(Request $request)
    {
        $device = $this->device($request);

        $patient = Patient::where('device_uuid', $device->device_uuid)->first();

        if (! $patient) {
            return $this->fail('Profil pasien tidak ditemukan', 404, 'not_found');
        }

        return $this->ok([
            'patient_uuid' => $patient->uuid,
            'name' => $patient->name,
            'age' => $patient->age,
            'height_cm' => $patient->height_cm,
            'weight_kg' => $patient->weight_kg,
            'gestational_weeks' => $patient->gestational_weeks,
            'due_date' => $patient->due_date?->toDateString(),
            'risk_level' => $patient->risk_level,
        ], 'Profil pasien');
    }
}
