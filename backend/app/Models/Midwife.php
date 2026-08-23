<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Storage;

class Midwife extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'name',
        'role',
        'phone',
        'alt_phone',
        'duty_hours',
        'workdays',
        'photo_path',
        'is_active',
        'notes',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'workdays' => 'array',
    ];

    protected $appends = ['photo_url'];

    public function getPhotoUrlAttribute(): ?string
    {
        return $this->photo_path ? Storage::disk('media')->url($this->photo_path) : null;
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true)->orderByDesc('created_at');
    }
}
