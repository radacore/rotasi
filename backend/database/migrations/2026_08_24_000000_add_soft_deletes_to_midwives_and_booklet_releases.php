<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('midwives', function (Blueprint $table) {
            $table->softDeletes();
        });
        Schema::table('booklet_releases', function (Blueprint $table) {
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::table('booklet_releases', function (Blueprint $table) {
            $table->dropSoftDeletes();
        });
        Schema::table('midwives', function (Blueprint $table) {
            $table->dropSoftDeletes();
        });
    }
};
