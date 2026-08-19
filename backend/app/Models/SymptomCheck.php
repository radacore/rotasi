<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SymptomCheck extends Model
{
    use HasUuids;

    protected $primaryKey = 'uuid';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'uuid',
        'patient_uuid',
        'checked_at',
        'headache',
        'blurred_vision',
        'epigastric_pain',
        'shortness_of_breath',
    ];

    protected $casts = [
        'checked_at' => 'datetime',
        'headache' => 'boolean',
        'blurred_vision' => 'boolean',
        'epigastric_pain' => 'boolean',
        'shortness_of_breath' => 'boolean',
    ];

    public function patient(): BelongsTo
    {
        return $this->belongsTo(Patient::class, 'patient_uuid', 'uuid');
    }
}
