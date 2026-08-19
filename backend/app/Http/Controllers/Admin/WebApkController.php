<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ApkRelease;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class WebApkController extends Controller
{
    public function index()
    {
        $releases = ApkRelease::orderByDesc('version_code')->paginate(15);

        return inertia('Apk/Index', [
            'releases' => $releases->through(fn ($r) => [
                'id' => $r->id,
                'version_code' => $r->version_code,
                'version_name' => $r->version_name,
                'release_notes' => $r->release_notes,
                'download_url' => $r->download_url,
                'is_active' => $r->is_active,
                'uploaded_at' => $r->uploaded_at?->toDateTimeString(),
            ]),
        ]);
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
            return back()->withErrors(['download_url' => 'download_url atau file apk wajib diisi.'])->withInput();
        }

        $release = ApkRelease::create([
            'version_code' => $data['version_code'],
            'version_name' => $data['version_name'],
            'release_notes' => $data['release_notes'] ?? null,
            'file_path' => $data['file_path'] ?? null,
            'download_url' => $downloadUrl,
            'uploaded_at' => now(),
        ]);

        if ($request->boolean('is_active')) {
            $release->activate();
        }

        return redirect()->route('apk.index')->with('success', 'Rilis APK diunggah.');
    }

    public function activate(ApkRelease $release)
    {
        $release->activate();

        return back()->with('success', 'Versi aktif diperbarui.');
    }

    public function destroy(ApkRelease $release)
    {
        if ($release->is_active) {
            return back()->withErrors(['delete' => 'Rilis aktif tidak dapat dihapus.']);
        }

        $release->delete();

        return redirect()->route('apk.index')->with('success', 'Rilis APK dihapus.');
    }
}
