<?php

namespace Tests\Feature;

use App\Models\Media;
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
        Storage::disk('media')->assertExists($booklet->file_path);

        $this->post("/booklet/{$booklet->id}/activate")->assertRedirect();
        $this->assertDatabaseHas('booklet_releases', ['id' => $booklet->id, 'is_active' => true]);

        $this->delete("/booklet/{$booklet->id}")->assertRedirect();
        $this->assertDatabaseHas('booklet_releases', ['id' => $booklet->id, 'is_active' => true]);

        $this->post("/booklet/{$booklet->id}/deactivate")->assertRedirect();
        $this->assertDatabaseHas('booklet_releases', ['id' => $booklet->id, 'is_active' => false]);

        $this->delete("/booklet/{$booklet->id}")->assertRedirect('/booklet');
        $this->assertDatabaseMissing('booklet_releases', ['id' => $booklet->id]);
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
        $this->assertDatabaseMissing('midwives', ['name' => 'Bidan Web']);
    }

    public function test_apk_and_settings_pages(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin);

        $this->get('/apk')->assertOk();
        $this->post('/apk', [
            'version_code' => 10,
            'version_name' => '1.0.10',
            'download_url' => 'https://example.com/app.apk',
        ])->assertRedirect('/apk');

        $this->get('/settings')->assertOk();
        $this->put('/settings', [
            'puskesmas_name' => 'Puskesmas Test',
            'kick_threshold' => 3,
        ])->assertRedirect('/settings');
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

    public function test_media_page_and_upload(): void
    {
        Storage::fake('media');

        $admin = $this->admin();
        $this->actingAs($admin);

        $this->get('/media')->assertOk();

        $png = base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');
        $path = tempnam(sys_get_temp_dir(), 'webimg');
        file_put_contents($path, $png);
        $file = new UploadedFile($path, 'ilustrasi.png', 'image/png', null, true);

        $this->post('/media', ['file' => $file])->assertRedirect();

        $media = Media::first();
        $this->assertNotNull($media);
        Storage::disk('media')->assertExists($media->disk_path);
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
