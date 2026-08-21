<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ApkRelease;
use App\Services\S3UploadWithProgress;
use Endroid\QrCode\Color\Color;
use Endroid\QrCode\ErrorCorrectionLevel;
use Endroid\QrCode\QrCode;
use Endroid\QrCode\Writer\PngWriter;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class WebApkController extends Controller
{
    public function __construct(private S3UploadWithProgress $uploads)
    {
    }

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
            'apk' => ['nullable', 'file', 'extensions:apk', 'max:307200'],
            'download_url' => ['nullable', 'string', 'max:500'],
            'is_active' => ['nullable', 'boolean'],
            'upload_token' => ['nullable', 'string', 'max:64'],
        ]);

        $downloadUrl = $data['download_url'] ?? null;
        $disk = Storage::disk('media');
        $filePath = null;

        if ($request->hasFile('apk')) {
            $file = $request->file('apk');

            try {
                $filePath = $this->uploads->upload(
                    'apk-releases',
                    $file->getPathname(),
                    str()->random(40).'.'.$file->getClientOriginalExtension(),
                    $file->getSize(),
                    $request->string('upload_token', ''),
                    $file->getClientOriginalName(),
                );
            } catch (\Throwable $e) {
                report($e);

                return $this->uploadFailed($request, 'Upload file ke penyimpanan gagal. Silakan coba lagi.');
            }

            $downloadUrl = $disk->url($filePath);
        }

        if (! $downloadUrl) {
            return $this->uploadFailed($request, 'download_url atau file apk wajib diisi.');
        }

        $release = ApkRelease::create([
            'version_code' => $data['version_code'],
            'version_name' => $data['version_name'],
            'release_notes' => $data['release_notes'] ?? null,
            'file_path' => $filePath,
            'download_url' => $downloadUrl,
            'uploaded_at' => now(),
        ]);

        if ($request->boolean('is_active')) {
            $release->activate();
        }

        if ($request->expectsJson()) {
            return response()->json([
                'message' => 'Rilis APK diunggah.',
                'release' => [
                    'id' => $release->id,
                    'version_code' => $release->version_code,
                    'version_name' => $release->version_name,
                    'download_url' => $release->download_url,
                    'is_active' => $release->is_active,
                    'uploaded_at' => $release->uploaded_at?->toDateTimeString(),
                ],
            ]);
        }

        return redirect()->route('apk.index')->with('success', 'Rilis APK diunggah.');
    }

    private function uploadFailed(Request $request, string $message)
    {
        if ($request->expectsJson()) {
            return response()->json(['message' => $message], 422);
        }

        return back()->withErrors(['apk' => $message])->withInput();
    }

    public function activate(ApkRelease $release)
    {
        $release->activate();

        return back()->with('success', 'Versi aktif diperbarui.');
    }

    public function qr(ApkRelease $release)
    {
        return $this->qrPng($release, false);
    }

    public function qrDownload(ApkRelease $release)
    {
        return $this->qrPng($release, true);
    }

    private function qrPng(ApkRelease $release, bool $download): \Illuminate\Http\Response
    {
        $qrCode = new QrCode(
            data: $release->download_url,
            errorCorrectionLevel: ErrorCorrectionLevel::High,
            size: 2000,
            margin: 20,
            foregroundColor: new Color(0, 0, 0),
            backgroundColor: new Color(255, 255, 255),
        );

        $png = (new PngWriter)->write($qrCode)->getString();
        $slug = str($release->version_name)->slug();
        $filename = "rotasi-{$slug}-qr.png";

        return response($png, 200, [
            'Content-Type' => 'image/png',
            'Cache-Control' => 'public, max-age=86400',
            ...($download ? ['Content-Disposition' => "attachment; filename=\"{$filename}\""] : []),
        ]);
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
