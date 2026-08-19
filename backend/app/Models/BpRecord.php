<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BpRecord extends Model
{
    use HasUuids;

    protected $primaryKey = 'uuid';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'uuid',
        'patient_uuid',
        'measured_at',
        'session_code',
        'systolic_1',
        'diastolic_1',
        'systolic_2',
        'diastolic_2',
        'avg_systolic',
        'avg_diastolic',
        'status_color',
    ];

    protected $casts = [
        'measured_at' => 'datetime',
        'systolic_1' => 'integer',
        'diastolic_1' => 'integer',
        'systolic_2' => 'integer',
        'diastolic_2' => 'integer',
        'avg_systolic' => 'integer',
        'avg_diastolic' => 'integer',
    ];

    public function patient(): BelongsTo
    {
        return $this->belongsTo(Patient::class, 'patient_uuid', 'uuid');
    }
}
