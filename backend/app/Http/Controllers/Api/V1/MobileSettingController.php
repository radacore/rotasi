<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Setting;

class MobileSettingController extends Controller
{
    public function index()
    {
        $get = fn (string $key, mixed $default = null) => Setting::getValue($key, $default);

        // Aturan rujukan dinamis — bila belum diatur admin, pakai default.
        $colorsRaw = $get('referral_persistent_colors', null);
        $colors = ['orange', 'red'];
        if ($colorsRaw !== null && $colorsRaw !== '') {
            $decoded = json_decode($colorsRaw, true);
            if (is_array($decoded) && $decoded !== []) {
                $colors = array_values(array_filter($decoded, fn ($v) => is_string($v) && $v !== ''));
                if ($colors === []) $colors = ['orange', 'red'];
            }
        }
        $symptomRaw = $get('referral_symptom_check_trigger', null);
        $symptomTrigger = $symptomRaw === null ? true : in_array(strtolower((string) $symptomRaw), ['1', 'true', 'yes'], true);
        $kickThreshold = (int) $get('kick_threshold', 3);
        if ($kickThreshold < 1) $kickThreshold = 3;

        return $this->ok([
            'app_name' => config('app.name'),
            'emergency_phone' => $get('emergency_phone', ''),
            'puskesmas_name' => $get('puskesmas_name', ''),
            'puskesmas_address' => $get('puskesmas_address', ''),
            'default_wa_message' => $get('default_wa_message', ''),
            'referral_rules' => [
                'persistent_colors' => $colors,
                'symptom_check_trigger' => $symptomTrigger,
                'kick_threshold' => $kickThreshold,
            ],
            'updated_at' => Setting::max('updated_at'),
        ], 'Pengaturan global');
    }
}
