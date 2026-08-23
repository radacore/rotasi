<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\BookletRelease;

class MobileBookletController extends Controller
{
    public function index(\Illuminate\Http\Request $request)
    {
        $releases = BookletRelease::where('is_active', true)
            ->orderByDesc('version')
            ->get(['id', 'title', 'version', 'file_url', 'file_size', 'uploaded_at', 'updated_at']);

        $updatedAt = $releases->max('updated_at');
        $effectiveUpdatedAt = $updatedAt ?? BookletRelease::max('updated_at');

        $since = $request->query('since');
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

        if ($releases->isEmpty()) {
            return response()->json([
                'success' => false,
                'error' => 'not_found',
                'message' => 'Belum ada booklet aktif',
                'updated_at' => $effectiveUpdatedAt?->toIso8601String(),
            ], 404);
        }

        $items = $releases->map(fn ($release) => [
            'id' => $release->id,
            'title' => $release->title,
            'version' => $release->version,
            'file_url' => $release->file_url,
            'file_size' => $release->file_size,
            'uploaded_at' => $release->uploaded_at?->toDateTimeString(),
        ])->values()->all();

        // Backward-compatible: `data` tetap List (HP lama), `updated_at` top-level untuk versioning hemat kuota (HP baru).
        return response()->json([
            'success' => true,
            'data' => $items,
            'message' => 'Daftar booklet aktif',
            'updated_at' => $effectiveUpdatedAt?->toIso8601String(),
        ]);
    }
}
