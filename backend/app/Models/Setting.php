<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    protected $primaryKey = 'setting_key';

    public $incrementing = false;

    public $timestamps = false;

    protected $keyType = 'string';

    protected $fillable = [
        'setting_key',
        'setting_value',
        'updated_at',
    ];

    protected $casts = [
        'updated_at' => 'datetime',
    ];

    public static function getValue(string $key, mixed $default = null): mixed
    {
        $row = static::find($key);

        return $row ? $row->setting_value : $default;
    }

    public static function setValue(string $key, mixed $value): void
    {
        static::updateOrCreate(
            ['setting_key' => $key],
            ['setting_value' => $value, 'updated_at' => now()],
        );
    }
}
