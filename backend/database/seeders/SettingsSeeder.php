<?php

namespace Database\Seeders;

use App\Models\Setting;
use Illuminate\Database\Seeder;

class SettingsSeeder extends Seeder
{
    public function run(): void
    {
        $defaults = [
            'puskesmas_name' => 'Puskesmas Barombong',
            'emergency_phone' => '119',
            'ambulance_phone' => '119',
            'reference_threshold_systolic' => '140',
            'reference_threshold_diastolic' => '90',
            'app_version_min' => '1.0.0',
            'referral_persistent_colors' => json_encode(['orange', 'red']),
            'referral_symptom_check_trigger' => '1',
            'kick_threshold' => '3',
        ];

        foreach ($defaults as $key => $value) {
            Setting::setValue($key, $value);
        }
    }
}
