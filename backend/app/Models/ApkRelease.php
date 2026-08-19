<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ApkRelease extends Model
{
    protected $fillable = [
        'version_code',
        'version_name',
        'release_notes',
        'file_path',
        'download_url',
        'is_active',
        'uploaded_at',
    ];

    protected $casts = [
        'version_code' => 'integer',
        'is_active' => 'boolean',
        'uploaded_at' => 'datetime',
    ];

    public function activate(): void
    {
        static::where('is_active', true)->update(['is_active' => false]);
        static::whereKey($this->id)->update(['is_active' => true]);
        $this->is_active = true;
    }
}
