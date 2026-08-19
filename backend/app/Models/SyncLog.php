<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SyncLog extends Model
{
    protected $fillable = [
        'device_uuid',
        'patient_uuid',
        'status',
        'records_count',
        'synced_at',
    ];

    protected $casts = [
        'records_count' => 'integer',
        'synced_at' => 'datetime',
    ];
}
