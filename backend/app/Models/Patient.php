<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Patient extends Model
{
    use HasUuids;

    protected $primaryKey = 'uuid';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'uuid',
        'device_uuid',
        'name',
        'age',
        'height_cm',
        'weight_kg',
        'gestational_weeks',
        'due_date',
        'last_systolic',
        'last_diastolic',
        'history_type',
        'risk_level',
        'phone',
    ];

    protected $casts = [
        'age' => 'integer',
        'height_cm' => 'decimal:1',
        'weight_kg' => 'decimal:1',
        'gestational_weeks' => 'integer',
        'due_date' => 'date',
        'last_systolic' => 'integer',
        'last_diastolic' => 'integer',
    ];

    public function bpRecords(): HasMany
    {
        return $this->hasMany(BpRecord::class, 'patient_uuid', 'uuid');
    }

    public function symptomChecks(): HasMany
    {
        return $this->hasMany(SymptomCheck::class, 'patient_uuid', 'uuid');
    }

    public function kickCounts(): HasMany
    {
        return $this->hasMany(KickCount::class, 'patient_uuid', 'uuid');
    }

    public function ancChecks(): HasMany
    {
        return $this->hasMany(AncCheck::class, 'patient_uuid', 'uuid');
    }
}
