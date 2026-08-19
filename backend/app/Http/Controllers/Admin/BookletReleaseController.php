<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BookletRelease;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class BookletReleaseController extends Controller
{
    public function index()
    {
        $items = BookletRelease::orderByDesc('version')->paginate(20);

        $items->getCollection()->transform(fn ($r) => [
            'id' => $r->id,
            'title' => $r->title,
            'version' => $r->version,
            'file_url' => $r->file_url,
            'file_size' => $r->file_size,
            'is_active' => $r->is_active,
            'uploaded_at' => $r->uploaded_at?->toDateTimeString(),
        ]);

        return $this->paginated($items, 'Daftar booklet');
    }

    public function show(int $id)
    {
        $release = BookletRelease::find($id);

        if (! $release) {
            return $this->fail('Booklet tidak ditemukan', 404, 'not_found');
        }

        return $this->ok([
            'id' => $release->id,
            'title' => $release->title,
            'version' => $release->version,
            'file_url' => $release->file_url,
            'file_size' => $release->file_size,
            'is_active' => $release->is_active,
            'uploaded_at' => $release->uploaded_at?->toDateTimeString(),
        ], 'Detail booklet');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'file' => ['required', 'file', 'mimes:pdf', 'max:30720'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $file = $request->file('file');
        $disk = Storage::disk('media');

        $path = $disk->putFile('booklets', $file, 'public');

        $version = (int) BookletRelease::max('version') + 1;

        $release = BookletRelease::create([
            'title' => $data['title'],
            'version' => $version,
            'file_path' => $path,
            'file_url' => $disk->url($path),
            'file_size' => $file->getSize(),
            'uploaded_at' => now(),
        ]);

        if ($request->boolean('is_active')) {
            $release->activate();
        }

        return $this->ok([
            'id' => $release->id,
            'title' => $release->title,
            'version' => $release->version,
            'file_url' => $release->file_url,
            'is_active' => $release->is_active,
        ], 'Booklet diunggah', 201);
    }

    public function activate(int $id)
    {
        $release = BookletRelease::find($id);

        if (! $release) {
            return $this->fail('Booklet tidak ditemukan', 404, 'not_found');
        }

        $release->activate();

        return $this->ok([
            'id' => $release->id,
            'version' => $release->version,
            'is_active' => $release->is_active,
        ], 'Versi aktif diperbarui');
    }

    public function deactivate(int $id)
    {
        $release = BookletRelease::find($id);

        if (! $release) {
            return $this->fail('Booklet tidak ditemukan', 404, 'not_found');
        }

        if (! $release->is_active) {
            return $this->fail('Booklet sudah nonaktif', 409, 'not_active');
        }

        $release->deactivate();

        return $this->ok([
            'id' => $release->id,
            'version' => $release->version,
            'is_active' => $release->is_active,
        ], 'Booklet dinonaktifkan');
    }

    public function destroy(int $id)
    {
        $release = BookletRelease::find($id);

        if (! $release) {
            return $this->fail('Booklet tidak ditemukan', 404, 'not_found');
        }

        if ($release->is_active) {
            return $this->fail('Booklet aktif tidak dapat dihapus', 409, 'active_release');
        }

        $release->delete();

        return $this->ok(null, 'Booklet dihapus');
    }
}
