<?php

namespace App\Models;

use Laravel\Sanctum\HasApiTokens;
use Illuminate\Foundation\Auth\User as Authenticatable;

class Device extends Authenticatable
{
    use HasApiTokens;

    protected $fillable = [
        'device_uuid',
        'android_id',
        'app_version',
        'device_name',
    ];

    protected $hidden = [
        'android_id',
    ];
}
