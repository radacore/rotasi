<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ApkRelease;

class ReleaseController extends Controller
{
    public function latest()
    {
        $release = ApkRelease::where('is_active', true)->first();

        if (! $release) {
            return $this->fail('Belum ada rilis aktif', 404, 'not_found');
        }

        return $this->ok([
            'version_code' => $release->version_code,
            'version_name' => $release->version_name,
            'release_notes' => $release->release_notes,
            'is_force_update' => false,
            'download_url' => $release->download_url,
        ], 'Rilis terbaru');
    }
}
