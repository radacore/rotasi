<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'mysql') {
            DB::statement("ALTER TABLE patients MODIFY risk_level ENUM('unknown','low','medium','high') NOT NULL DEFAULT 'unknown'");
            // Pasien lama tanpa tensi yang masih 'low' palsu -> 'unknown'
            DB::table('patients')
                ->where('risk_level', 'low')
                ->where(function ($q) {
                    $q->whereNull('last_systolic')->orWhereNull('last_diastolic');
                })
                ->whereNotExists(function ($q) {
                    $q->select(DB::raw(1))->from('bp_records')
                        ->whereColumn('bp_records.patient_uuid', 'patients.uuid');
                })
                ->update(['risk_level' => 'unknown']);
            DB::statement("ALTER TABLE patients ALTER risk_level SET DEFAULT 'unknown'");
        } else {
            // sqlite (testing): enum = CHECK constraint via string; cukup update data + default via raw
            DB::table('patients')
                ->where('risk_level', 'low')
                ->where(function ($q) {
                    $q->whereNull('last_systolic')->orWhereNull('last_diastolic');
                })
                ->whereNotExists(function ($q) {
                    $q->select(DB::raw(1))->from('bp_records')
                        ->whereColumn('bp_records.patient_uuid', 'patients.uuid');
                })
                ->update(['risk_level' => 'unknown']);
        }
    }

    public function down(): void
    {
        $driver = DB::getDriverName();
        // Kembalikan unknown -> low agar rollback aman
        DB::table('patients')->where('risk_level', 'unknown')->update(['risk_level' => 'low']);
        if ($driver === 'mysql') {
            DB::statement("ALTER TABLE patients MODIFY risk_level ENUM('low','medium','high') NOT NULL DEFAULT 'low'");
        }
    }
};
