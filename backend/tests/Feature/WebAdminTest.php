<?php

namespace Tests\Feature;

use App\Models\Midwife;
use App\Models\Patient;
use App\Models\SyncLog;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class WebAdminTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::factory()->create(['password' => bcrypt('secret123')]);
    }

    public function test_login_page_renders(): void
    {
        $this->get('/login')->assertOk();
    }

    public function test_guest_is_redirected_from_dashboard(): void
    {
        $this->get('/dashboard')->assertRedirect('/login');
    }

    public function test_admin_can_login_and_access_dashboard(): void
    {
        $admin = $this->admin();

        $this->post('/login', ['email' => $admin->email, 'password' => 'secret123'])
            ->assertRedirect('/dashboard');

        $this->actingAs($admin)->get('/dashboard')->assertOk();
    }

    public function test_booklet_upload_and_activate_flow(): void
    {
        Storage::fake('media');
        $this->mock(\App\Services\S3UploadWithProgress::class, function ($mock) {
            $mock->shouldReceive('upload')->once()->andReturn('booklets/fake-booklet.pdf');
        });

        $admin = $this->admin();
        $this->actingAs($admin);

        $this->get('/booklet')->assertOk();

        $path = tempnam(sys_get_temp_dir(), 'booklet');
        file_put_contents($path, "%PDF-1.4\n%âãÏÓ\n1 0 obj\n<< /Type /Catalog >>\nendobj\n%%EOF\n");
        $file = new UploadedFile($path, 'booklet.pdf', 'application/pdf', null, true);

        $this->post('/booklet', [
            'title' => 'Booklet Web',
            'file' => $file,
            'is_active' => '1',
        ])->assertRedirect('/booklet');

        $this->assertDatabaseHas('booklet_releases', ['title' => 'Booklet Web', 'is_active' => true]);

        $booklet = \App\Models\BookletRelease::where('title', 'Booklet Web')->first();
        $this->assertNotNull($booklet);
        $this->assertEquals('booklets/fake-booklet.pdf', $booklet->file_path);
        $this->assertNotNull($booklet->file_url);

        $this->post("/booklet/{$booklet->id}/activate")->assertRedirect();
        $this->assertDatabaseHas('booklet_releases', ['id' => $booklet->id, 'is_active' => true]);

        $this->delete("/booklet/{$booklet->id}")->assertRedirect();
        $this->assertDatabaseHas('booklet_releases', ['id' => $booklet->id, 'is_active' => true]);

        $this->post("/booklet/{$booklet->id}/deactivate")->assertRedirect();
        $this->assertDatabaseHas('booklet_releases', ['id' => $booklet->id, 'is_active' => false]);

        $this->delete("/booklet/{$booklet->id}")->assertRedirect('/booklet');
        $this->assertSoftDeleted('booklet_releases', ['id' => $booklet->id]);
    }

    public function test_booklet_upload_fails_without_silent_broken_record(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin);

        $this->mock(\App\Services\S3UploadWithProgress::class, function ($mock) {
            $mock->shouldReceive('upload')->once()->andThrow(new \RuntimeException('s3 down'));
        });

        $file = UploadedFile::fake()->create('booklet-gagal.pdf', 1024, 'application/pdf');

        $this->post('/booklet', ['title' => 'Gagal Upload', 'file' => $file])
            ->assertSessionHasErrors('file');

        $this->assertDatabaseMissing('booklet_releases', ['title' => 'Gagal Upload']);
    }

    public function test_booklet_upload_responds_json_for_ajax(): void
    {
        Storage::fake('media');
        $this->mock(\App\Services\S3UploadWithProgress::class, function ($mock) {
            $mock->shouldReceive('upload')->once()->andReturn('booklets/fake-json.pdf');
        });

        $admin = $this->admin();
        $this->actingAs($admin);

        $path = tempnam(sys_get_temp_dir(), 'booklet');
        file_put_contents($path, "%PDF-1.4\n%âãÏÓ\n1 0 obj\n<< /Type /Catalog >>\nendobj\n%%EOF\n");
        $file = new UploadedFile($path, 'booklet-json.pdf', 'application/pdf', null, true);

        $this->postJson('/booklet', [
            'title' => 'Booklet JSON',
            'file' => $file,
        ])->assertOk()
            ->assertJson(['message' => 'Booklet diunggah.'])
            ->assertJsonPath('release.title', 'Booklet JSON');

        $this->assertDatabaseHas('booklet_releases', ['title' => 'Booklet JSON']);
    }

    public function test_booklet_upload_responds_json_error_for_failed_storage(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin);

        $this->mock(\App\Services\S3UploadWithProgress::class, function ($mock) {
            $mock->shouldReceive('upload')->once()->andThrow(new \RuntimeException('s3 down'));
        });

        $file = UploadedFile::fake()->create('booklet-gagal-json.pdf', 1024, 'application/pdf');

        $this->postJson('/booklet', ['title' => 'Gagal JSON', 'file' => $file])
            ->assertStatus(422)
            ->assertJson(['message' => 'Upload file ke penyimpanan gagal. Silakan coba lagi.']);

        $this->assertDatabaseMissing('booklet_releases', ['title' => 'Gagal JSON']);
    }

    public function test_midwife_crud_flow(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin);

        Storage::fake('media');

        $this->get('/midwives')->assertOk();
        $this->get('/midwives/create')->assertOk();

        $this->post('/midwives', [
            'name' => 'Bidan Web',
            'role' => 'Bidan',
            'phone' => '6281200000001',
            'is_active' => true,
            'duty_hours_start' => '08:00',
            'duty_hours_end' => '14:00',
            'workdays' => ['Senin', 'Rabu', 'Jumat'],
            'photo' => UploadedFile::fake()->image('bidan.jpg'),
        ])->assertRedirect('/midwives');

        $midwife = Midwife::where('name', 'Bidan Web')->first();
        $this->assertNotNull($midwife);
        $this->assertEquals('08:00-14:00', $midwife->duty_hours);
        $this->assertEquals(['Senin', 'Rabu', 'Jumat'], $midwife->workdays);
        $this->assertNotNull($midwife->photo_path);
        Storage::disk('media')->assertExists($midwife->photo_path);

        $this->get("/midwives/{$midwife->id}/edit")->assertOk();
        $oldPath = $midwife->photo_path;
        $this->put("/midwives/{$midwife->id}", [
            'name' => 'Bidan Web',
            'role' => 'Bidan',
            'phone' => '6281200000001',
            'is_active' => true,
            'remove_photo' => true,
        ])->assertRedirect('/midwives');

        $this->assertNull($midwife->refresh()->photo_path);
        Storage::disk('media')->assertMissing($oldPath);

        $this->delete("/midwives/{$midwife->id}")->assertRedirect('/midwives');
        $this->assertSoftDeleted('midwives', ['name' => 'Bidan Web']);
    }

    public function test_apk_upload_stores_to_media_disk_and_qr_routes(): void
    {
        Storage::fake('media');
        $this->mock(\App\Services\S3UploadWithProgress::class, function ($mock) {
            $mock->shouldReceive('upload')->once()->andReturn('apk-releases/fake-rotasi.apk');
        });

        $admin = $this->admin();
        $this->actingAs($admin);

        $this->get('/apk')->assertOk();

        $path = tempnam(sys_get_temp_dir(), 'apk');
        file_put_contents($path, 'PK' . random_bytes(128));
        $file = new UploadedFile($path, 'rotasi.apk', 'application/vnd.android.package-archive', null, true);

        $this->post('/apk', [
            'version_code' => 11,
            'version_name' => '1.1.0',
            'release_notes' => 'Rilis QR',
            'apk' => $file,
            'is_active' => '1',
        ])->assertRedirect('/apk');

        $this->assertDatabaseHas('apk_releases', ['version_code' => 11, 'version_name' => '1.1.0', 'is_active' => true]);

        $release = \App\Models\ApkRelease::where('version_code', 11)->first();
        $this->assertNotNull($release);
        $this->assertNotNull($release->file_path);
        $this->assertEquals('apk-releases/fake-rotasi.apk', $release->file_path);
        $this->assertEquals(Storage::disk('media')->url($release->file_path), $release->download_url);

        $this->get("/apk/{$release->id}/qr")
            ->assertOk()
            ->assertHeader('Content-Type', 'image/png');

        $response = $this->get("/apk/{$release->id}/qr/download");
        $response->assertOk();
        $this->assertStringContainsString('attachment;', $response->headers->get('Content-Disposition'));
        $this->assertStringStartsWith("\x89PNG", $response->content());

        $this->get('/settings')->assertOk();
        $this->put('/settings', [
            'puskesmas_name' => 'Puskesmas Test',
            'kick_threshold' => 3,
        ])->assertRedirect('/settings');
    }

    public function test_apk_upload_rejects_without_file(): void
    {
        Storage::fake('media');
        $this->mock(\App\Services\S3UploadWithProgress::class);

        $admin = $this->admin();
        $this->actingAs($admin);

        $this->post('/apk', [
            'version_code' => 12,
            'version_name' => '1.2.0',
            'download_url' => 'https://example.com/app.apk',
        ])->assertSessionHasErrors('apk');

        $this->assertDatabaseMissing('apk_releases', ['version_code' => 12]);
    }

    public function test_apk_upload_auto_activates(): void
    {
        Storage::fake('media');
        $this->mock(\App\Services\S3UploadWithProgress::class, function ($mock) {
            $mock->shouldReceive('upload')->once()->andReturn('apk-releases/fake-auto.apk');
        });

        $admin = $this->admin();
        $this->actingAs($admin);

        $path = tempnam(sys_get_temp_dir(), 'apk');
        file_put_contents($path, 'PK' . random_bytes(128));
        $file = new UploadedFile($path, 'rotasi-1.2.0.apk', 'application/vnd.android.package-archive', null, true);

        $this->post('/apk', [
            'version_code' => 13,
            'version_name' => '1.2.0',
            'apk' => $file,
        ])->assertRedirect('/apk');

        $this->assertDatabaseHas('apk_releases', ['version_code' => 13, 'is_active' => true]);
        $this->assertDatabaseMissing('apk_releases', ['is_active' => false, 'version_code' => 13]);
    }

    public function test_apk_upload_fails_without_silent_broken_record(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin);

        $this->mock(\App\Services\S3UploadWithProgress::class, function ($mock) {
            $mock->shouldReceive('upload')->once()->andThrow(new \RuntimeException('s3 down'));
        });

        $file = UploadedFile::fake()->create('apk-gagal.apk', 1024, 'application/vnd.android.package-archive');

        $this->post('/apk', [
            'version_code' => 99,
            'version_name' => '9.9.0',
            'apk' => $file,
        ])->assertSessionHasErrors('apk');

        $this->assertDatabaseMissing('apk_releases', ['version_code' => 99]);
    }

    public function test_upload_progress_endpoint_reports_cached_progress(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin);

        \Illuminate\Support\Facades\Cache::put(
            \App\Services\S3UploadWithProgress::PROGRESS_PREFIX.'demo-token',
            ['uploaded' => 5242880, 'total' => 10485760],
            now()->addMinutes(5),
        );

        $this->get('/uploads/progress/demo-token')
            ->assertOk()
            ->assertJson(['uploaded' => 5242880, 'total' => 10485760, 'percent' => 50]);
    }

    public function test_upload_progress_endpoint_returns_zero_for_unknown_token(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin);

        $this->get('/uploads/progress/tidak-ada')
            ->assertOk()
            ->assertJson(['uploaded' => 0, 'total' => 0, 'percent' => 0]);
    }

    public function test_patients_and_sync_log_pages(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin);

        $patient = Patient::create([
            'device_uuid' => '22222222-2222-2222-2222-222222222222',
            'name' => 'Ibu Sari',
            'age' => 28,
            'height_cm' => 155,
            'weight_kg' => 60,
            'risk_level' => 'high',
            'gestational_weeks' => 30,
        ]);

        SyncLog::create([
            'device_uuid' => '11111111-1111-1111-1111-111111111111',
            'patient_uuid' => $patient->uuid,
            'status' => 'success',
            'records_count' => 5,
            'synced_at' => now(),
        ]);

        $this->get('/patients')->assertOk();
        $this->get('/patients?risk=high')->assertOk();
        $this->get("/patients/{$patient->uuid}")->assertOk()->assertSee('Ibu Sari');

        $this->get('/sync-logs')->assertOk();
        $this->get('/sync-logs?status=success')->assertOk();
    }

    public function test_account_change_password(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin);

        $this->put('/account', [
            'current_password' => 'secret123',
            'new_password' => 'password-baru',
            'new_password_confirmation' => 'password-baru',
        ])->assertRedirect('/account');

        $this->assertTrue(password_verify('password-baru', $admin->fresh()->password));

        $this->put('/account', [
            'current_password' => 'salah',
            'new_password' => 'password-baru-2',
            'new_password_confirmation' => 'password-baru-2',
        ])->assertSessionHasErrors('current_password');
    }
}
