<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\Request;

class SettingController extends Controller
{
    public function show()
    {
        $get = fn (string $k, mixed $d = null) => Setting::getValue($k, $d);

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

        return $this->ok([
            'app_name' => config('app.name'),
            'emergency_phone' => $get('emergency_phone', ''),
            'puskesmas_name' => $get('puskesmas_name', ''),
            'puskesmas_address' => $get('puskesmas_address', ''),
            'default_wa_message' => $get('default_wa_message', ''),
            'kick_threshold' => (int) $get('kick_threshold', 3),
            'referral_persistent_colors' => $colors,
            'referral_symptom_check_trigger' => $symptomTrigger,
            'updated_at' => Setting::max('updated_at'),
        ], 'Pengaturan global');
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'emergency_phone' => ['nullable', 'string', 'max:30'],
            'puskesmas_name' => ['nullable', 'string', 'max:150'],
            'puskesmas_address' => ['nullable', 'string', 'max:255'],
            'default_wa_message' => ['nullable', 'string'],
            'kick_threshold' => ['nullable', 'integer', 'min:1'],
            'referral_persistent_colors' => ['nullable', 'array', 'min:1'],
            'referral_persistent_colors.*' => ['string', 'in:green,yellow,orange,red'],
            'referral_symptom_check_trigger' => ['nullable', 'boolean'],
        ]);

        foreach ($data as $key => $value) {
            if ($value === null) continue;
            if ($key === 'referral_persistent_colors') {
                Setting::setValue($key, json_encode(array_values($value)));
            } elseif ($key === 'referral_symptom_check_trigger') {
                Setting::setValue($key, $value ? '1' : '0');
            } else {
                Setting::setValue($key, (string) $value);
            }
        }

        return $this->ok(null, 'Pengaturan diperbarui');
    }
}
