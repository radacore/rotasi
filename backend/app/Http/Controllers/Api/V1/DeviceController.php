<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Device;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class DeviceController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate([
            'android_id' => ['required', 'string', 'max:255'],
            'app_version' => ['required', 'string', 'max:50'],
            'device_name' => ['nullable', 'string', 'max:255'],
        ]);

        $device = Device::where('android_id', $data['android_id'])->first();

        if (! $device) {
            $device = Device::create([
                'device_uuid' => (string) Str::uuid(),
                'android_id' => $data['android_id'],
                'app_version' => $data['app_version'],
                'device_name' => $data['device_name'] ?? null,
            ]);
        }

        $token = $device->createToken('mobile')->plainTextToken;

        return $this->ok([
            'device_uuid' => $device->device_uuid,
            'token' => $token,
        ], 'Perangkat terdaftar', 201);
    }
}
