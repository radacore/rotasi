<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BookletRelease;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class WebBookletController extends Controller
{
    public function index()
    {
        $releases = BookletRelease::orderByDesc('version')->paginate(15)->withQueryString();

        return inertia('Booklet/Index', [
            'releases' => $releases->through(fn ($r) => [
                'id' => $r->id,
                'title' => $r->title,
                'version' => $r->version,
                'file_url' => $r->file_url,
                'file_size' => $r->file_size,
                'is_active' => $r->is_active,
                'uploaded_at' => $r->uploaded_at?->toDateTimeString(),
            ]),
        ]);
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

        return redirect()->route('booklet.index')->with('success', 'Booklet diunggah.');
    }

    public function activate(BookletRelease $release)
    {
        $release->activate();

        return back()->with('success', 'Versi aktif diperbarui.');
    }

    public function deactivate(BookletRelease $release)
    {
        if (! $release->is_active) {
            return back()->withErrors(['delete' => 'Booklet sudah nonaktif.']);
        }

        $release->deactivate();

        return back()->with('success', 'Booklet dinonaktifkan.');
    }

    public function destroy(BookletRelease $release)
    {
        if ($release->is_active) {
            return back()->withErrors(['delete' => 'Booklet aktif tidak dapat dihapus.']);
        }

        $release->delete();

        return redirect()->route('booklet.index')->with('success', 'Booklet dihapus.');
    }
}
