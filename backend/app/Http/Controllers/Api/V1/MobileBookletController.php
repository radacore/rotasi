<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\BookletRelease;

class MobileBookletController extends Controller
{
    public function index()
    {
        $release = BookletRelease::where('is_active', true)->first();

        if (! $release) {
            return $this->fail('Belum ada booklet aktif', 404, 'not_found');
        }

        return $this->ok([
            'id' => $release->id,
            'title' => $release->title,
            'version' => $release->version,
            'file_url' => $release->file_url,
            'file_size' => $release->file_size,
            'uploaded_at' => $release->uploaded_at?->toDateTimeString(),
        ], 'Booklet aktif');
    }
}
