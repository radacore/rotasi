<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Media;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class WebMediaController extends Controller
{
    public function index(Request $request)
    {
        $media = Media::orderByDesc('id')->paginate(20)->withQueryString();

        $media->getCollection()->transform(fn ($m) => [
            'id' => $m->id,
            'filename' => $m->filename,
            'original_filename' => $m->original_filename,
            'mime_type' => $m->mime_type,
            'file_size' => $m->file_size,
            'url' => $m->url,
            'created_at' => $m->created_at?->toDateTimeString(),
        ]);

        return inertia('Media/Index', ['media' => $media]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'file' => ['required', 'file', 'image', 'max:10240'],
        ]);

        $file = $request->file('file');
        $disk = Storage::disk('media');

        try {
            $path = $disk->putFile('media', $file, 'public');
        } catch (\Throwable $e) {
            report($e);

            return back()->withErrors(['file' => 'Upload file ke penyimpanan gagal. Silakan coba lagi.']);
        }

        if (! $path) {
            return back()->withErrors(['file' => 'Upload file ke penyimpanan gagal. Silakan coba lagi.']);
        }

        $media = Media::create([
            'filename' => basename($path),
            'original_filename' => $file->getClientOriginalName(),
            'mime_type' => $file->getClientMimeType(),
            'file_size' => $file->getSize(),
            'disk_path' => $path,
            'url' => $disk->url($path),
        ]);

        if ($request->expectsJson()) {
            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $media->id,
                    'filename' => $media->filename,
                    'original_filename' => $media->original_filename,
                    'url' => $media->url,
                    'file_size' => $media->file_size,
                ],
                'message' => 'Gambar diunggah.',
            ], 201);
        }

        return back()->with('success', 'Gambar diunggah.');
    }

    public function destroy(Media $media)
    {
        Storage::disk('media')->delete($media->disk_path);
        $media->delete();

        return back()->with('success', 'Media dihapus.');
    }
}
