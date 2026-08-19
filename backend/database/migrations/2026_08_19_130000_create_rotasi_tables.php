<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('patients', function (Blueprint $table) {
            $table->char('uuid', 36)->primary();
            $table->char('device_uuid', 36);
            $table->string('name', 100);
            $table->unsignedTinyInteger('age');
            $table->decimal('height_cm', 5, 1);
            $table->decimal('weight_kg', 5, 1);
            $table->unsignedTinyInteger('gestational_weeks')->nullable();
            $table->date('due_date')->nullable();
            $table->smallInteger('last_systolic')->nullable();
            $table->smallInteger('last_diastolic')->nullable();
            $table->enum('history_type', ['none', 'hypertension', 'prior_preeclampsia', 'family'])->default('none');
            $table->enum('risk_level', ['low', 'medium', 'high'])->default('low');
            $table->string('phone', 20)->nullable();
            $table->timestamps();
            $table->index('risk_level');
            $table->index('device_uuid');
        });

        Schema::create('bp_records', function (Blueprint $table) {
            $table->char('uuid', 36)->primary();
            $table->foreignUuid('patient_uuid')->constrained('patients', 'uuid')->cascadeOnDelete();
            $table->dateTime('measured_at');
            $table->enum('session_code', ['pagi', 'sore']);
            $table->smallInteger('systolic_1');
            $table->smallInteger('diastolic_1');
            $table->smallInteger('systolic_2');
            $table->smallInteger('diastolic_2');
            $table->smallInteger('avg_systolic');
            $table->smallInteger('avg_diastolic');
            $table->enum('status_color', ['green', 'yellow', 'orange', 'red']);
            $table->timestamps();
            $table->index(['patient_uuid', 'measured_at']);
            $table->index(['patient_uuid', 'status_color']);
        });

        Schema::create('symptom_checks', function (Blueprint $table) {
            $table->char('uuid', 36)->primary();
            $table->foreignUuid('patient_uuid')->constrained('patients', 'uuid')->cascadeOnDelete();
            $table->dateTime('checked_at');
            $table->boolean('headache')->default(false);
            $table->boolean('blurred_vision')->default(false);
            $table->boolean('epigastric_pain')->default(false);
            $table->boolean('shortness_of_breath')->default(false);
            $table->timestamps();
            $table->index(['patient_uuid', 'checked_at']);
        });

        Schema::create('kick_counts', function (Blueprint $table) {
            $table->char('uuid', 36)->primary();
            $table->foreignUuid('patient_uuid')->constrained('patients', 'uuid')->cascadeOnDelete();
            $table->dateTime('started_at');
            $table->dateTime('ended_at')->nullable();
            $table->smallInteger('kick_count')->default(0);
            $table->boolean('is_active')->default(false);
            $table->timestamps();
            $table->index(['patient_uuid', 'started_at']);
        });

        Schema::create('anc_checks', function (Blueprint $table) {
            $table->char('uuid', 36)->primary();
            $table->foreignUuid('patient_uuid')->constrained('patients', 'uuid')->cascadeOnDelete();
            $table->date('visited_at');
            $table->json('t_items');
            $table->timestamps();
            $table->index(['patient_uuid', 'visited_at']);
        });

        Schema::create('contents', function (Blueprint $table) {
            $table->id();
            $table->string('key', 100)->unique();
            $table->string('title');
            $table->longText('body');
            $table->enum('category', ['preeclampsia', 'dash', '1000hpk', 'stress', 'postpartum', 'other']);
            $table->enum('status', ['draft', 'published'])->default('draft');
            $table->unsignedInteger('version')->default(1);
            $table->unsignedInteger('display_order')->default(0);
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
            $table->index(['status', 'display_order']);
        });

        Schema::create('content_versions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('content_id')->constrained('contents')->cascadeOnDelete();
            $table->string('title');
            $table->longText('body');
            $table->string('category', 50);
            $table->text('change_note')->nullable();
            $table->foreignId('admin_id')->constrained('users')->restrictOnDelete();
            $table->timestamps();
            $table->index('content_id');
        });

        Schema::create('media', function (Blueprint $table) {
            $table->id();
            $table->string('filename');
            $table->string('original_filename');
            $table->string('mime_type', 100);
            $table->integer('file_size');
            $table->string('disk_path');
            $table->string('url');
            $table->timestamps();
        });

        Schema::create('content_media', function (Blueprint $table) {
            $table->id();
            $table->foreignId('content_id')->constrained('contents')->cascadeOnDelete();
            $table->foreignId('media_id')->constrained('media')->cascadeOnDelete();
            $table->unique(['content_id', 'media_id']);
        });

        Schema::create('apk_releases', function (Blueprint $table) {
            $table->id();
            $table->integer('version_code')->unique();
            $table->string('version_name', 50);
            $table->text('release_notes')->nullable();
            $table->string('file_path')->nullable();
            $table->string('download_url', 500);
            $table->boolean('is_active')->default(false);
            $table->timestamp('uploaded_at')->nullable();
            $table->timestamps();
        });

        Schema::create('settings', function (Blueprint $table) {
            $table->string('setting_key', 100)->primary();
            $table->text('setting_value');
            $table->timestamp('updated_at')->nullable();
        });

        Schema::create('midwives', function (Blueprint $table) {
            $table->id();
            $table->string('name', 150);
            $table->string('role', 100)->nullable();
            $table->string('puskesmas', 150)->nullable();
            $table->string('phone', 30);
            $table->string('alt_phone', 30)->nullable();
            $table->string('duty_hours', 150)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('sort_order')->default(0);
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->index(['is_active', 'sort_order']);
        });

        Schema::create('sync_logs', function (Blueprint $table) {
            $table->id();
            $table->char('device_uuid', 36);
            $table->char('patient_uuid', 36)->nullable();
            $table->enum('status', ['success', 'failed']);
            $table->integer('records_count')->default(0);
            $table->timestamp('synced_at')->nullable();
            $table->timestamps();
            $table->index(['patient_uuid', 'synced_at']);
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sync_logs');
        Schema::dropIfExists('midwives');
        Schema::dropIfExists('settings');
        Schema::dropIfExists('apk_releases');
        Schema::dropIfExists('content_media');
        Schema::dropIfExists('media');
        Schema::dropIfExists('content_versions');
        Schema::dropIfExists('contents');
        Schema::dropIfExists('anc_checks');
        Schema::dropIfExists('kick_counts');
        Schema::dropIfExists('symptom_checks');
        Schema::dropIfExists('bp_records');
        Schema::dropIfExists('patients');
    }
};
