<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Setting;

class MobileSettingController extends Controller
{
    public function index()
    {
        $get = fn (string $key, mixed $default = null) => Setting::getValue($key, $default);

        return $this->ok([
            'app_name' => config('app.name'),
            'emergency_phone' => $get('emergency_phone', ''),
            'puskesmas_name' => $get('puskesmas_name', ''),
            'puskesmas_address' => $get('puskesmas_address', ''),
            'default_wa_message' => $get('default_wa_message', ''),
            'referral_rules' => [
                'persistent_colors' => ['orange', 'red'],
                'symptom_check_trigger' => true,
                'kick_threshold' => 3,
            ],
        ], 'Pengaturan global');
    }
}
