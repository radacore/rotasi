<?php

namespace Database\Seeders;

use App\Models\Midwife;
use Illuminate\Database\Seeder;

class MidwifeSeeder extends Seeder
{
    public function run(): void
    {
        $bidans = [
            [
                'name' => 'Bidan Sitti',
                'role' => 'Bidan Koordinator',
                'phone' => '6281234500001',
                'alt_phone' => null,
                'duty_hours' => '08:00-14:00',
                'workdays' => ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'],
                'photo_path' => null,
                'is_active' => true,
                'notes' => 'Koordinator program ROTASI.',
            ],
            [
                'name' => 'Bidan Rahma',
                'role' => 'Bidan Pelaksana',
                'phone' => '6281234500002',
                'alt_phone' => '6281234500003',
                'duty_hours' => '14:00-20:00',
                'workdays' => ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'],
                'photo_path' => null,
                'is_active' => true,
                'notes' => null,
            ],
        ];

        foreach ($bidans as $data) {
            Midwife::updateOrCreate(['phone' => $data['phone']], $data);
        }
    }
}
