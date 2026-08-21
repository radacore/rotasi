<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BookletRelease;
use App\Services\S3UploadWithProgress;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class WebBookletController extends Controller
{
    public function __construct(private S3UploadWithProgress $uploads)
    {
    }

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
            'upload_token' => ['nullable', 'string', 'max:64'],
        ]);

        $file = $request->file('file');
        $disk = Storage::disk('media');

        $errorMessage = 'Upload file ke penyimpanan gagal. Silakan coba lagi.';

        try {
            $path = $this->uploads->upload(
                'booklets',
                $file->getPathname(),
                str()->random(40).'.'.$file->getClientOriginalExtension(),
                $file->getSize(),
                $request->string('upload_token', ''),
                $file->getClientOriginalName(),
            );
        } catch (\Throwable $e) {
            report($e);

            return $this->uploadFailed($request, $errorMessage);
        }

        if (! $path) {
            return $this->uploadFailed($request, $errorMessage);
        }

        $version = (int) BookletRelease::max('id') + 1;

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

        if ($request->expectsJson()) {
            return response()->json([
                'message' => 'Booklet diunggah.',
                'release' => [
                    'id' => $release->id,
                    'title' => $release->title,
                    'version' => $release->version,
                    'file_url' => $release->file_url,
                    'file_size' => $release->file_size,
                    'is_active' => $release->is_active,
                    'uploaded_at' => $release->uploaded_at?->toDateTimeString(),
                ],
            ]);
        }

        return redirect()->route('booklet.index')->with('success', 'Booklet diunggah.');
    }

    private function uploadFailed(Request $request, string $message)
    {
        if ($request->expectsJson()) {
            return response()->json(['message' => $message], 422);
        }

        return back()->withErrors(['file' => $message])->withInput();
    }

    public function activate(BookletRelease $release)
    {
        $release->activate();

        return back()->with('success', 'Booklet diaktifkan.');
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
