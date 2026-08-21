<?php

namespace Tests\Feature;

use App\Models\ApkRelease;
use App\Models\BpRecord;
use App\Models\Media;
use App\Models\Midwife;
use App\Models\Patient;
use App\Models\SyncLog;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ApiCoverageTest extends TestCase
{
    use RefreshDatabase;

    private function deviceToken(): string
    {
        return $this->postJson('/api/v1/device/register', [
            'android_id' => 'cov-' . uniqid(),
            'app_version' => '1.0.0',
        ])->json('data.token');
    }

    private function adminToken(): string
    {
        $admin = User::factory()->create(['password' => bcrypt('secret123')]);
        return $this->postJson('/api/admin/login', [
            'email' => $admin->email, 'password' => 'secret123',
        ])->json('data.token');
    }

    public function test_single_sync_endpoints(): void
    {
        $token = $this->deviceToken();
        $uuid = 'aaaaaaaa-1111-1111-1111-111111111111';

        $this->withToken($token)->putJson('/api/v1/patient', [
            'patient_uuid' => $uuid, 'name' => 'Ibu', 'age' => 30,
            'height_cm' => 160, 'weight_kg' => 60,
            'history_type' => 'none', 'risk_level' => 'low',
        ])->assertOk();

        $this->withToken($token)->postJson('/api/v1/sync/bp', [
            'patient_uuid' => $uuid,
            'uuid' => 'bbbbbbbb-2222-2222-2222-222222222222',
            'measured_at' => now()->toDateTimeString(), 'session_code' => 'pagi',
            'systolic_1' => 120, 'diastolic_1' => 80, 'systolic_2' => 122, 'diastolic_2' => 82,
            'avg_systolic' => 121, 'avg_diastolic' => 81, 'status_color' => 'green',
        ])->assertCreated();

        $this->withToken($token)->postJson('/api/v1/sync/symptom', [
            'patient_uuid' => $uuid,
            'uuid' => 'cccccccc-3333-3333-3333-333333333333',
            'checked_at' => now()->toDateTimeString(), 'headache' => true,
        ])->assertCreated();

        $this->withToken($token)->postJson('/api/v1/sync/kick', [
            'patient_uuid' => $uuid,
            'uuid' => 'dddddddd-4444-4444-4444-444444444444',
            'started_at' => now()->toDateTimeString(), 'kick_count' => 5, 'is_active' => true,
        ])->assertCreated();

        $this->withToken($token)->postJson('/api/v1/sync/anc', [
            'patient_uuid' => $uuid,
            'uuid' => 'eeeeeeee-5555-5555-5555-555555555555',
            'visited_at' => now()->toDateString(), 't_items' => ['t1' => true],
        ])->assertCreated();
    }

    public function test_duplicate_sync_is_ignored(): void
    {
        $token = $this->deviceToken();
        $uuid = 'ffffffff-6666-6666-6666-666666666666';
        $this->withToken($token)->putJson('/api/v1/patient', [
            'patient_uuid' => $uuid, 'name' => 'Ibu', 'age' => 30,
            'height_cm' => 160, 'weight_kg' => 60,
            'history_type' => 'none', 'risk_level' => 'low',
        ])->assertOk();

        $payload = ['patient_uuid' => $uuid,
            'uuid' => 'abcabcab-7777-7777-7777-777777777777',
            'measured_at' => now()->toDateTimeString(), 'session_code' => 'pagi',
            'systolic_1' => 120, 'diastolic_1' => 80, 'systolic_2' => 122, 'diastolic_2' => 82,
            'avg_systolic' => 121, 'avg_diastolic' => 81, 'status_color' => 'green'];

        $this->withToken($token)->postJson('/api/v1/sync/bp', $payload)->assertCreated();
        $this->withToken($token)->postJson('/api/v1/sync/bp', $payload)->assertOk();
    }

    public function test_booklet_version_increments_on_upload(): void
    {
        Storage::fake('media');
        $this->mock(\App\Services\S3UploadWithProgress::class, function ($mock) {
            $mock->shouldReceive('upload')->twice()->andReturn('booklets/fake-api.pdf');
        });
        $token = $this->adminToken();

        $path = tempnam(sys_get_temp_dir(), 'booklet');
        file_put_contents($path, "%PDF-1.4\n%âãÏÓ\n1 0 obj\n<< /Type /Catalog >>\nendobj\n%%EOF\n");

        $first = $this->withToken($token)->postJson('/api/admin/booklet-releases', [
            'title' => 'Booklet Satu',
            'file' => new UploadedFile($path, 'booklet.pdf', 'application/pdf', null, true),
        ])->assertCreated()->json('data');
        $this->assertEquals(1, $first['version']);

        $second = $this->withToken($token)->postJson('/api/admin/booklet-releases', [
            'title' => 'Booklet Dua',
            'file' => new UploadedFile($path, 'booklet.pdf', 'application/pdf', null, true),
        ])->assertCreated()->json('data');
        $this->assertEquals(2, $second['version']);
    }

    public function test_admin_midwife_api_crud(): void
    {
        $token = $this->adminToken();

        $id = $this->withToken($token)->postJson('/api/admin/midwives', [
            'name' => 'Bidan API', 'role' => 'Bidan', 'phone' => '6281200000099', 'is_active' => true,
        ])->assertCreated()->json('data.id');

        $this->withToken($token)->getJson('/api/admin/midwives')->assertOk();
        $this->withToken($token)->getJson("/api/admin/midwives/{$id}")->assertOk();
        $this->withToken($token)->putJson("/api/admin/midwives/{$id}", [
            'name' => 'Bidan API', 'phone' => '6281200000099', 'is_active' => false,
        ])->assertOk();
        $this->withToken($token)->deleteJson("/api/admin/midwives/{$id}")->assertOk();
        $this->assertDatabaseMissing('midwives', ['id' => $id]);
    }

    public function test_admin_settings_api(): void
    {
        $token = $this->adminToken();
        $this->withToken($token)->getJson('/api/admin/settings')->assertOk();
        $this->withToken($token)->putJson('/api/admin/settings', [
            'puskesmas_name' => 'Puskesmas X', 'kick_threshold' => 4,
        ])->assertOk();
    }

    public function test_admin_patients_and_sync_logs(): void
    {
        $token = $this->adminToken();
        $patient = Patient::create([
            'uuid' => '99999999-1111-1111-1111-111111111111', 'device_uuid' => 'dev-1',
            'name' => 'Ibu X', 'age' => 28, 'height_cm' => 158, 'weight_kg' => 55,
            'history_type' => 'none', 'risk_level' => 'low',
        ]);
        BpRecord::create([
            'uuid' => '88888888-2222-2222-2222-222222222222', 'patient_uuid' => $patient->uuid,
            'measured_at' => now(), 'session_code' => 'pagi',
            'systolic_1' => 120, 'diastolic_1' => 80, 'systolic_2' => 122, 'diastolic_2' => 82,
            'avg_systolic' => 121, 'avg_diastolic' => 81, 'status_color' => 'green',
        ]);
        SyncLog::create([
            'device_uuid' => 'dev-1', 'patient_uuid' => $patient->uuid, 'status' => 'success',
            'records_count' => 1, 'synced_at' => now(),
        ]);

        $this->withToken($token)->getJson('/api/admin/patients')->assertOk();
        $this->withToken($token)->getJson("/api/admin/patients/{$patient->uuid}")->assertOk();
        $this->withToken($token)->getJson('/api/admin/sync-logs')->assertOk();
    }

    public function test_admin_dashboard(): void
    {
        $token = $this->adminToken();
        $this->withToken($token)->getJson('/api/admin/dashboard')
            ->assertOk()
            ->assertJsonStructure(['data' => ['stats', 'recent_syncs']]);
    }

    public function test_apk_file_upload(): void
    {
        Storage::fake('media');
        $this->mock(\App\Services\S3UploadWithProgress::class, function ($mock) {
            $mock->shouldReceive('upload')->once()->andReturn('apk-releases/fake-api.apk');
        });
        $token = $this->adminToken();

        $path = tempnam(sys_get_temp_dir(), 'apk');
        file_put_contents($path, 'dummy-apk-content');
        $file = new UploadedFile($path, 'app.apk', 'application/vnd.android.package-archive', null, true);
        $this->withToken($token)->postJson('/api/admin/apk-releases', [
            'version_code' => 100,
            'version_name' => '1.0.100',
            'apk' => $file,
            'is_active' => true,
        ])->assertCreated();

        $release = ApkRelease::where('version_code', 100)->first();
        $this->assertNotNull($release);
        $this->assertTrue($release->is_active);
        $this->assertEquals('apk-releases/fake-api.apk', $release->file_path);
    }

    public function test_admin_media_upload_to_object_storage(): void
    {
        Storage::fake('media');
        $token = $this->adminToken();

        $png = base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');
        $path = tempnam(sys_get_temp_dir(), 'img');
        file_put_contents($path, $png);
        $file = new UploadedFile($path, 'ilustrasi.png', 'image/png', null, true);

        $resp = $this->withToken($token)
            ->postJson('/api/admin/media', ['file' => $file])
            ->assertCreated();

        $this->assertArrayHasKey('url', $resp->json('data'));

        $media = Media::first();
        $this->assertNotNull($media);
        Storage::disk('media')->assertExists($media->disk_path);
    }
}
