<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Media extends Model
{
    protected $fillable = [
        'filename',
        'original_filename',
        'mime_type',
        'file_size',
        'disk_path',
        'url',
    ];

    protected $casts = [
        'file_size' => 'integer',
    ];
}
