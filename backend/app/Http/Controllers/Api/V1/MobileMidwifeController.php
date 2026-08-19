<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Midwife;

class MobileMidwifeController extends Controller
{
    public function index()
    {
        $midwives = Midwife::active()->get(['id', 'name', 'role', 'phone', 'duty_hours']);

        return $this->ok(
            $midwives->map(fn ($m) => [
                'id' => $m->id,
                'name' => $m->name,
                'role' => $m->role,
                'phone' => $m->phone,
            ])->all(),
            'Daftar bidan aktif'
        );
    }
}
