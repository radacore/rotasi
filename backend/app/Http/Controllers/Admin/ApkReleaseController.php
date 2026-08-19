<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ApkRelease;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ApkReleaseController extends Controller
{
    public function index()
    {
        $items = ApkRelease::orderByDesc('version_code')->paginate(20);

        return $this->paginated($items, 'Daftar rilis APK');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'version_code' => ['required', 'integer', 'min:1', 'unique:apk_releases,version_code'],
            'version_name' => ['required', 'string', 'max:50'],
            'release_notes' => ['nullable', 'string'],
            'apk' => ['nullable', 'file', 'extensions:apk', 'max:102400'],
            'download_url' => ['nullable', 'string', 'max:500'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $downloadUrl = $data['download_url'] ?? null;

        if ($request->hasFile('apk')) {
            $path = $request->file('apk')->store('releases', 'public');
            $downloadUrl = Storage::disk('public')->url($path);
            $data['file_path'] = $path;
        }

        if (! $downloadUrl) {
            return $this->fail('download_url atau file apk wajib diisi', 422, 'validation');
        }

        $data['download_url'] = $downloadUrl;

        $release = ApkRelease::create([
            'version_code' => $data['version_code'],
            'version_name' => $data['version_name'],
            'release_notes' => $data['release_notes'] ?? null,
            'file_path' => $data['file_path'] ?? null,
            'download_url' => $data['download_url'],
            'uploaded_at' => now(),
        ]);

        if ($request->boolean('is_active')) {
            $release->activate();
        }

        return $this->ok([
            'id' => $release->id,
            'version_code' => $release->version_code,
            'version_name' => $release->version_name,
            'release_notes' => $release->release_notes,
            'download_url' => $release->download_url,
            'is_active' => $release->is_active,
        ], 'Rilis APK diunggah', 201);
    }

    public function activate(int $id)
    {
        $release = ApkRelease::find($id);

        if (! $release) {
            return $this->fail('Rilis tidak ditemukan', 404, 'not_found');
        }

        $release->activate();

        return $this->ok([
            'id' => $release->id,
            'version_code' => $release->version_code,
            'is_active' => $release->is_active,
        ], 'Versi aktif diperbarui');
    }

    public function destroy(int $id)
    {
        $release = ApkRelease::find($id);

        if (! $release) {
            return $this->fail('Rilis tidak ditemukan', 404, 'not_found');
        }

        if ($release->is_active) {
            return $this->fail('Rilis aktif tidak dapat dihapus', 409, 'active_release');
        }

        $release->delete();

        return $this->ok(null, 'Rilis APK dihapus');
    }
}
