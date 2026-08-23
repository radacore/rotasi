<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Midwife;

class MobileMidwifeController extends Controller
{
    public function index(\Illuminate\Http\Request $request)
    {
        $since = $request->query('since');
        $midwives = Midwife::active()->get(['id', 'name', 'role', 'phone', 'updated_at']);
        $updatedAt = $midwives->max('updated_at');
        // Bila semua nonaktif, active kosong → updated_at null. Pakai global max
        // agar HP tetap dapat sinyal versi dan mengosongkan cache bila admin sengaja kosongkan.
        $effectiveUpdatedAt = $updatedAt ?? Midwife::max('updated_at');

        // Conditional GET: bila client sudah punya versi terbaru, kembalikan 304
        if ($since !== null && $since !== '' && $effectiveUpdatedAt !== null) {
            try {
                $sinceTime = \Carbon\Carbon::parse($since);
                if ($effectiveUpdatedAt->lte($sinceTime)) {
                    return response()->json(null, 304);
                }
            } catch (\Throwable) {
                // abaikan since tidak valid — kembalikan penuh
            }
        }

        $items = $midwives->map(fn ($m) => [
            'id' => $m->id,
            'name' => $m->name,
            'role' => $m->role,
            'phone' => $m->phone,
        ])->all();

        // Backward-compatible: `data` tetap List (HP lama), `updated_at` di top-level
        // untuk versioning hemat kuota (HP baru baca `updated_at` + `since`).
        return response()->json([
            'success' => true,
            'data' => $items,
            'message' => 'Daftar bidan aktif',
            'updated_at' => $effectiveUpdatedAt?->toIso8601String(),
        ]);
    }
}
