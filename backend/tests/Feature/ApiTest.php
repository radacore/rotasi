<?php

namespace Tests\Feature;

use App\Models\ApkRelease;
use App\Models\BookletRelease;
use App\Models\Midwife;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_device_register_returns_token(): void
    {
        $response = $this->postJson('/api/v1/device/register', [
            'android_id' => 'device-x',
            'app_version' => '1.0.0',
        ]);

        $response->assertCreated()
            ->assertJsonStructure(['success', 'data' => ['device_uuid', 'token'], 'message']);

        $this->assertNotEmpty($response->json('data.token'));
    }

    public function test_mobile_full_flow(): void
    {
        $register = $this->postJson('/api/v1/device/register', [
            'android_id' => 'device-y',
            'app_version' => '1.0.0',
        ]);
        $token = $register->json('data.token');

        $uuid = '11111111-1111-1111-1111-111111111111';

        $this->withToken($token)
            ->putJson('/api/v1/patient', [
                'patient_uuid' => $uuid,
                'name' => 'Ibu Test',
                'age' => 30,
                'height_cm' => 160,
                'weight_kg' => 60,
                'history_type' => 'none',
                'risk_level' => 'low',
            ])
            ->assertOk()
            ->assertJsonPath('data.sync_status', 'synced');

        $this->withToken($token)
            ->postJson('/api/v1/sync', [
                'patient_uuid' => $uuid,
                'records' => [
                    'bp_records' => [[
                        'uuid' => '22222222-2222-2222-2222-222222222222',
                        'measured_at' => now()->toDateTimeString(),
                        'session_code' => 'pagi',
                        'systolic_1' => 120, 'diastolic_1' => 80,
                        'systolic_2' => 122, 'diastolic_2' => 82,
                        'avg_systolic' => 121, 'avg_diastolic' => 81,
                        'status_color' => 'green',
                    ]],
                ],
            ])
            ->assertOk()
            ->assertJsonPath('data.accepted_bp.0', '22222222-2222-2222-2222-222222222222');

        BookletRelease::create([
            'title' => 'Booklet Aktif',
            'version' => 3,
            'file_url' => 'https://example.com/booklet.pdf',
            'file_size' => 2048,
            'is_active' => true,
            'uploaded_at' => now(),
        ]);

        $this->withToken($token)->getJson('/api/v1/booklet')
            ->assertOk()
            ->assertJsonPath('data.0.version', 3);

        $this->withToken($token)->getJson('/api/v1/settings')->assertOk();
        $this->withToken($token)->getJson('/api/v1/midwives')->assertOk();
        $this->withToken($token)->getJson('/api/v1/app/latest-release')->assertStatus(404);
    }

    public function test_admin_can_manage_booklet(): void
    {
        Storage::fake('media');
        $this->mock(\App\Services\S3UploadWithProgress::class, function ($mock) {
            $mock->shouldReceive('upload')->once()->andReturn('booklets/fake-admin.pdf');
        });

        $admin = User::factory()->create(['password' => bcrypt('secret123')]);

        $login = $this->postJson('/api/admin/login', [
            'email' => $admin->email,
            'password' => 'secret123',
        ]);
        $login->assertOk();
        $token = $login->json('data.token');

        $path = tempnam(sys_get_temp_dir(), 'booklet');
        file_put_contents($path, "%PDF-1.4\n%âãÏÓ\n1 0 obj\n<< /Type /Catalog >>\nendobj\n%%EOF\n");
        $file = new UploadedFile($path, 'booklet.pdf', 'application/pdf', null, true);

        $create = $this->withToken($token)->postJson('/api/admin/booklet-releases', [
            'title' => 'Booklet Admin',
            'file' => $file,
            'is_active' => true,
        ]);
        $create->assertCreated();
        $id = $create->json('data.id');

        $this->withToken($token)->getJson('/api/admin/booklet-releases')->assertOk();
        $this->withToken($token)->getJson("/api/admin/booklet-releases/{$id}")->assertOk();
        $this->withToken($token)->putJson("/api/admin/booklet-releases/{$id}/activate")
            ->assertOk()
            ->assertJsonPath('data.is_active', true);

        $this->withToken($token)->deleteJson("/api/admin/booklet-releases/{$id}")->assertStatus(409);

        $release = BookletRelease::find($id);
        $this->assertNotNull($release);
        $this->assertEquals('booklets/fake-admin.pdf', $release->file_path);

        $this->withToken($token)->putJson("/api/admin/booklet-releases/{$id}/deactivate")
            ->assertOk()
            ->assertJsonPath('data.is_active', false);

        $this->withToken($token)->deleteJson("/api/admin/booklet-releases/{$id}")->assertOk();
        $this->assertNull(BookletRelease::find($id));
    }

    public function test_multiple_active_booklets_are_all_returned(): void
    {
        $register = $this->postJson('/api/v1/device/register', [
            'android_id' => 'device-booklet',
            'app_version' => '1.0.0',
        ]);
        $token = $register->json('data.token');

        $first = BookletRelease::create([
            'title' => 'Booklet Satu',
            'version' => 1,
            'file_path' => 'booklets/satu.pdf',
            'file_url' => 'https://example.com/satu.pdf',
            'file_size' => 1024,
            'is_active' => true,
            'uploaded_at' => now(),
        ]);

        $second = BookletRelease::create([
            'title' => 'Booklet Dua',
            'version' => 2,
            'file_path' => 'booklets/dua.pdf',
            'file_url' => 'https://example.com/dua.pdf',
            'file_size' => 2048,
            'is_active' => true,
            'uploaded_at' => now(),
        ]);

        $response = $this->withToken($token)->getJson('/api/v1/booklet');
        $response->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.id', $second->id)
            ->assertJsonPath('data.1.id', $first->id);

        $first->deactivate();

        $this->withToken($token)->getJson('/api/v1/booklet')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $second->id);
    }

    public function test_admin_requires_auth(): void
    {
        $this->getJson('/api/admin/dashboard')->assertStatus(401);
    }

    public function test_mobile_requires_device_token(): void
    {
        $this->getJson('/api/v1/settings')->assertStatus(401);
    }

    public function test_apk_release_activate(): void
    {
        $this->mock(\App\Services\S3UploadWithProgress::class);

        $admin = User::factory()->create(['password' => bcrypt('secret123')]);
        $token = $this->postJson('/api/admin/login', [
            'email' => $admin->email, 'password' => 'secret123',
        ])->json('data.token');

        $release = ApkRelease::create([
            'version_code' => 2,
            'version_name' => '1.0.1',
            'download_url' => 'https://example.com/app.apk',
            'uploaded_at' => now(),
        ]);

        $this->withToken($token)->putJson("/api/admin/apk-releases/{$release->id}/activate")
            ->assertOk();

        $this->assertTrue($release->fresh()->is_active);
    }

    public function test_latest_release_returns_active(): void
    {
        ApkRelease::create([
            'version_code' => 3,
            'version_name' => '1.0.2',
            'download_url' => 'https://example.com/app.apk',
            'is_active' => true,
            'uploaded_at' => now(),
        ]);

        $deviceToken = $this->postJson('/api/v1/device/register', [
            'android_id' => 'device-z',
            'app_version' => '1.0.0',
        ])->json('data.token');

        $this->withToken($deviceToken)->getJson('/api/v1/app/latest-release')
            ->assertOk()
            ->assertJsonPath('data.version_code', 3);
    }
}
