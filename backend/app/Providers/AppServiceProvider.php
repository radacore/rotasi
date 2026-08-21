<?php

namespace App\Providers;

use App\Services\S3UploadWithProgress;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(S3UploadWithProgress::class, function () {
            $disk = Storage::disk('media');

            return new S3UploadWithProgress(
                $disk->getClient(),
                config('filesystems.disks.media.bucket'),
            );
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
