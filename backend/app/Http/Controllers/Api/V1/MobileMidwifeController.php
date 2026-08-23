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
        // Soft delete: baris terhapus tetap bump deleted_at sehingga max mundur.
        // Pakai withTrashed max agar hapus tetap memaju effectiveUpdatedAt dan 304 tidak palsu.
        $effectiveUpdatedAt = $updatedAt
            ?? Midwife::withTrashed()->max('updated_at')
            ?? Midwife::withTrashed()->max('deleted_at');

        // Conditional GET: bila client sudah punya versi terbaru, kembalikan 304.
        // Guard tambahan: bila ada soft-deleted setelah `since`, jangan 304
        // walau active max mundur — HP perlu list baru (hapus).
        if ($since !== null && $since !== '' && $effectiveUpdatedAt !== null) {
            try {
                $sinceTime = \Carbon\Carbon::parse($since);
                if ($effectiveUpdatedAt->lte($sinceTime)) {
                    $recentlyDeleted = Midwife::onlyTrashed()
                        ->where('deleted_at', '>', $sinceTime)
                        ->exists();
                    if (! $recentlyDeleted) {
                        return response()->json(null, 304);
                    }
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
