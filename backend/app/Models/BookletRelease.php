<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BookletRelease extends Model
{
    protected $fillable = [
        'title',
        'version',
        'file_path',
        'file_url',
        'file_size',
        'is_active',
        'uploaded_at',
    ];

    protected $casts = [
        'version' => 'integer',
        'file_size' => 'integer',
        'is_active' => 'boolean',
        'uploaded_at' => 'datetime',
    ];

    public function activate(): void
    {
        static::whereKey($this->id)->update(['is_active' => true]);
        $this->is_active = true;
    }

    public function deactivate(): void
    {
        static::whereKey($this->id)->update(['is_active' => false]);
        $this->is_active = false;
    }
}
