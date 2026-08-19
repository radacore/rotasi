<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('devices', function (Blueprint $table) {
            $table->id();
            $table->char('device_uuid', 36)->unique();
            $table->string('android_id');
            $table->string('app_version');
            $table->string('device_name')->nullable();
            $table->timestamps();
            $table->index('android_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('devices');
    }
};
