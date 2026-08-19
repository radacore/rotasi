<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('booklet_releases', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->unsignedInteger('version')->unique();
            $table->string('file_path')->nullable();
            $table->string('file_url', 500);
            $table->integer('file_size')->nullable();
            $table->boolean('is_active')->default(false);
            $table->timestamp('uploaded_at')->nullable();
            $table->timestamps();
            $table->index('is_active');
        });

        Schema::dropIfExists('content_media');
        Schema::dropIfExists('content_versions');
        Schema::dropIfExists('contents');
    }

    public function down(): void
    {
        Schema::dropIfExists('booklet_releases');
    }
};
