<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Media;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class MediaController extends Controller
{
    public function index(Request $request)
    {
        $perPage = min((int) $request->query('per_page', 20), 100);
        $items = Media::orderByDesc('id')->paginate($perPage);

        return $this->paginated($items, 'Daftar media');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'file' => ['required', 'file', 'image', 'max:10240'],
        ]);

        $file = $request->file('file');
        $disk = Storage::disk('media');

        $path = $disk->putFile('media', $file, 'public');

        $media = Media::create([
            'filename' => basename($path),
            'original_filename' => $file->getClientOriginalName(),
            'mime_type' => $file->getClientMimeType(),
            'file_size' => $file->getSize(),
            'disk_path' => $path,
            'url' => $disk->url($path),
        ]);

        return $this->ok([
            'id' => $media->id,
            'filename' => $media->filename,
            'url' => $media->url,
            'type' => 'image',
            'size' => $media->file_size,
        ], 'Media diunggah', 201);
    }

    public function destroy(int $id)
    {
        $media = Media::find($id);

        if (! $media) {
            return $this->fail('Media tidak ditemukan', 404, 'not_found');
        }

        Storage::disk('media')->delete($media->disk_path);
        $media->delete();

        return $this->ok(null, 'Media dihapus');
    }
}
