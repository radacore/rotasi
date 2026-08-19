<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('midwives', function (Blueprint $table) {
            $table->dropIndex(['is_active', 'sort_order']);
            $table->dropColumn(['puskesmas', 'sort_order']);
            $table->string('photo_path')->nullable()->after('duty_hours');
            $table->index('is_active');
        });
    }

    public function down(): void
    {
        Schema::table('midwives', function (Blueprint $table) {
            $table->dropIndex(['is_active']);
            $table->dropColumn('photo_path');
            $table->string('puskesmas', 150)->nullable()->after('role');
            $table->unsignedInteger('sort_order')->default(0)->after('is_active');
            $table->index(['is_active', 'sort_order']);
        });
    }
};
