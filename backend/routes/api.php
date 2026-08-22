<?php

use App\Http\Controllers\Admin\ApkReleaseController;
use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\BookletReleaseController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\MidwifeController;
use App\Http\Controllers\Admin\PatientController as AdminPatientController;
use App\Http\Controllers\Admin\SettingController;
use App\Http\Controllers\Admin\SyncLogController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\MobileBookletController;
use App\Http\Controllers\Api\V1\MobileMidwifeController;
use App\Http\Controllers\Api\V1\MobileSettingController;
use App\Http\Controllers\Api\V1\PatientController;
use App\Http\Controllers\Api\V1\ReleaseController;
use App\Http\Controllers\Api\V1\SyncController;
use App\Http\Middleware\EnsureDeviceAuth;
use App\Http\Middleware\EnsureUserAuth;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('device/register', [DeviceController::class, 'register']);

    Route::middleware(['auth:sanctum', EnsureDeviceAuth::class])->group(function () {
        Route::put('patient', [PatientController::class, 'upsert']);
        Route::get('patient', [PatientController::class, 'show']);
        Route::post('sync', [SyncController::class, 'sync']);
        Route::post('sync/bp', [SyncController::class, 'bp']);
        Route::post('sync/symptom', [SyncController::class, 'symptom']);
        Route::post('sync/kick', [SyncController::class, 'kick']);
        Route::post('sync/anc', [SyncController::class, 'anc']);
        Route::get('booklet', [MobileBookletController::class, 'index']);
        Route::get('settings', [MobileSettingController::class, 'index']);
        Route::get('midwives', [MobileMidwifeController::class, 'index']);
        Route::get('app/latest-release', [ReleaseController::class, 'latest']);
    });
});

Route::prefix('admin')->group(function () {
    Route::post('login', [AuthController::class, 'login'])->middleware('throttle:5,15');

    Route::middleware(['auth:sanctum', EnsureUserAuth::class])->group(function () {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::get('user', [AuthController::class, 'user']);

        Route::get('dashboard', [DashboardController::class, 'index']);

        Route::get('booklet-releases', [BookletReleaseController::class, 'index']);
        Route::post('booklet-releases', [BookletReleaseController::class, 'store']);
        Route::get('booklet-releases/{id}', [BookletReleaseController::class, 'show']);
        Route::put('booklet-releases/{id}/activate', [BookletReleaseController::class, 'activate']);
        Route::put('booklet-releases/{id}/deactivate', [BookletReleaseController::class, 'deactivate']);
        Route::delete('booklet-releases/{id}', [BookletReleaseController::class, 'destroy']);

        Route::get('midwives', [MidwifeController::class, 'index']);
        Route::post('midwives', [MidwifeController::class, 'store']);
        Route::get('midwives/{id}', [MidwifeController::class, 'show']);
        Route::put('midwives/{id}', [MidwifeController::class, 'update']);
        Route::delete('midwives/{id}', [MidwifeController::class, 'destroy']);

        Route::get('settings', [SettingController::class, 'show']);
        Route::put('settings', [SettingController::class, 'update']);

        Route::get('patients', [AdminPatientController::class, 'index']);
        Route::get('patients/{patientUuid}', [AdminPatientController::class, 'show']);

        Route::get('sync-logs', [SyncLogController::class, 'index']);

        Route::get('apk-releases', [ApkReleaseController::class, 'index']);
        Route::post('apk-releases', [ApkReleaseController::class, 'store']);
        Route::put('apk-releases/{id}/activate', [ApkReleaseController::class, 'activate']);
        Route::delete('apk-releases/{id}', [ApkReleaseController::class, 'destroy']);
    });
});
