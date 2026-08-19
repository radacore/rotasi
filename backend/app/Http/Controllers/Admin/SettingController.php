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

        return $this->ok([
            'app_name' => config('app.name'),
            'emergency_phone' => $get('emergency_phone', ''),
            'puskesmas_name' => $get('puskesmas_name', ''),
            'puskesmas_address' => $get('puskesmas_address', ''),
            'default_wa_message' => $get('default_wa_message', ''),
            'kick_threshold' => (int) $get('kick_threshold', 3),
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
        ]);

        foreach ($data as $key => $value) {
            if ($value !== null) {
                Setting::setValue($key, (string) $value);
            }
        }

        return $this->ok(null, 'Pengaturan diperbarui');
    }
}
