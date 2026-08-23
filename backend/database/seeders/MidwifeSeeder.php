<?php

namespace Database\Seeders;

use App\Models\Midwife;
use Illuminate\Database\Seeder;

class MidwifeSeeder extends Seeder
{
    public function run(): void
    {
        // 8 bidan = sama dengan VPS https://rotasi.my.id/midwives (offline bundle HP)
        $bidans = [
            ['name' => 'Dwi Luqsianti, A.Md.Keb', 'role' => 'Bidan', 'phone' => '081227088315'],
            ['name' => 'Nurafni Oktavia, A.Md.Keb', 'role' => 'Bidan', 'phone' => '085298805432'],
            ['name' => 'Mariama, A.Md.Keb', 'role' => 'Bidan', 'phone' => '085298130870'],
            ['name' => 'Desi T. Tangdialla, A.Md.Keb', 'role' => 'Bidan', 'phone' => '082190463407'],
            ['name' => 'Nurwana, A.Md.Keb', 'role' => 'Bidan', 'phone' => '081949982378'],
            ['name' => 'Eka Purwari Handayani, A.Md.Keb', 'role' => 'Bidan', 'phone' => '085143606520'],
            ['name' => 'Nurlinda, A.Md.Keb', 'role' => 'Bidan', 'phone' => '082271300683'],
            ['name' => 'Zulpina, A.Md.Keb', 'role' => 'Bidan', 'phone' => '081243803846'],
        ];

        foreach ($bidans as $data) {
            Midwife::updateOrCreate(['phone' => $data['phone']], [
                'name' => $data['name'],
                'role' => $data['role'],
                'is_active' => true,
            ]);
        }
    }
}
