<?php

use App\Http\Controllers\Admin\WebAccountController;
use App\Http\Controllers\Admin\WebApkController;
use App\Http\Controllers\Admin\WebAuthController;
use App\Http\Controllers\Admin\WebBookletController;
use App\Http\Controllers\Admin\WebDashboardController;
use App\Http\Controllers\Admin\WebMediaController;
use App\Http\Controllers\Admin\WebMidwifeController;
use App\Http\Controllers\Admin\WebPatientController;
use App\Http\Controllers\Admin\WebSettingController;
use App\Http\Controllers\Admin\WebSyncLogController;
use Illuminate\Support\Facades\Route;

Route::get('/login', [WebAuthController::class, 'showLogin'])->name('login')->middleware('guest');

Route::post('/login', [WebAuthController::class, 'login']);
Route::post('/logout', [WebAuthController::class, 'logout'])->middleware('auth');

Route::middleware('auth')->group(function () {
    Route::get('/', fn () => redirect()->route('dashboard'));

    Route::get('/dashboard', [WebDashboardController::class, 'index'])->name('dashboard');

    Route::get('/booklet', [WebBookletController::class, 'index'])->name('booklet.index');
    Route::post('/booklet', [WebBookletController::class, 'store'])->name('booklet.store');
    Route::post('/booklet/{release}/activate', [WebBookletController::class, 'activate'])->name('booklet.activate');
    Route::post('/booklet/{release}/deactivate', [WebBookletController::class, 'deactivate'])->name('booklet.deactivate');
    Route::delete('/booklet/{release}', [WebBookletController::class, 'destroy'])->name('booklet.destroy');

    Route::get('/patients', [WebPatientController::class, 'index'])->name('patients.index');
    Route::get('/patients/{patientUuid}', [WebPatientController::class, 'show'])->name('patients.show');

    Route::get('/sync-logs', [WebSyncLogController::class, 'index'])->name('sync-logs.index');

    Route::get('/media', [WebMediaController::class, 'index'])->name('media.index');
    Route::post('/media', [WebMediaController::class, 'store'])->name('media.store');
    Route::delete('/media/{media}', [WebMediaController::class, 'destroy'])->name('media.destroy');

    Route::get('/account', [WebAccountController::class, 'edit'])->name('account.edit');
    Route::put('/account', [WebAccountController::class, 'update'])->name('account.update');

    Route::get('/midwives', [WebMidwifeController::class, 'index'])->name('midwives.index');
    Route::get('/midwives/create', [WebMidwifeController::class, 'create'])->name('midwives.create');
    Route::post('/midwives', [WebMidwifeController::class, 'store'])->name('midwives.store');
    Route::get('/midwives/{midwife}/edit', [WebMidwifeController::class, 'edit'])->name('midwives.edit');
    Route::put('/midwives/{midwife}', [WebMidwifeController::class, 'update'])->name('midwives.update');
    Route::delete('/midwives/{midwife}', [WebMidwifeController::class, 'destroy'])->name('midwives.destroy');

    Route::get('/apk', [WebApkController::class, 'index'])->name('apk.index');
    Route::post('/apk', [WebApkController::class, 'store'])->name('apk.store');
    Route::post('/apk/{release}/activate', [WebApkController::class, 'activate'])->name('apk.activate');
    Route::delete('/apk/{release}', [WebApkController::class, 'destroy'])->name('apk.destroy');

    Route::get('/settings', [WebSettingController::class, 'edit'])->name('settings.edit');
    Route::put('/settings', [WebSettingController::class, 'update'])->name('settings.update');
});
