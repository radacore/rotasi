<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\S3UploadWithProgress;

class WebUploadController extends Controller
{
    public function progress(S3UploadWithProgress $uploads, string $token)
    {
        $data = $uploads->readProgress($token);

        if (! $data) {
            return response()->json(['uploaded' => 0, 'total' => 0, 'percent' => 0]);
        }

        $percent = $data['total'] > 0 ? ($data['uploaded'] / $data['total'] * 100) : 0;

        return response()->json([
            'uploaded' => $data['uploaded'],
            'total' => $data['total'],
            'percent' => (int) round(min($percent, 100)),
        ]);
    }
}
