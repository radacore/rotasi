<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Midwife;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class MidwifeController extends Controller
{
    public function index(Request $request)
    {
        $query = Midwife::query()->orderByDesc('created_at');

        if ($request->query('is_active') !== null) {
            $query->where('is_active', $request->boolean('is_active'));
        }

        $perPage = min((int) $request->query('per_page', 20), 100);
        $items = $query->paginate($perPage);

        return $this->paginated($items, 'Daftar bidan');
    }

    public function store(Request $request)
    {
        $data = $this->validated($request);
        $data['duty_hours'] = $this->dutyHours($request);

        if ($request->hasFile('photo')) {
            $data['photo_path'] = Storage::disk('media')->putFile('midwives', $request->file('photo'), 'public');
        }

        $midwife = Midwife::create($data);

        return $this->ok($midwife->toArray(), 'Bidan dibuat', 201);
    }

    public function show(int $id)
    {
        $midwife = Midwife::find($id);

        if (! $midwife) {
            return $this->fail('Bidan tidak ditemukan', 404, 'not_found');
        }

        return $this->ok($midwife->toArray(), 'Detail bidan');
    }

    public function update(Request $request, int $id)
    {
        $midwife = Midwife::find($id);

        if (! $midwife) {
            return $this->fail('Bidan tidak ditemukan', 404, 'not_found');
        }

        $data = $this->validated($request);
        $data['duty_hours'] = $this->dutyHours($request);

        $disk = Storage::disk('media');

        if ($request->hasFile('photo')) {
            if ($midwife->photo_path) {
                $disk->delete($midwife->photo_path);
            }
            $data['photo_path'] = $disk->putFile('midwives', $request->file('photo'), 'public');
        }

        if ($request->boolean('remove_photo')) {
            if ($midwife->photo_path) {
                $disk->delete($midwife->photo_path);
            }
            $data['photo_path'] = null;
        }

        $midwife->update($data);

        return $this->ok($midwife->toArray(), 'Bidan diubah');
    }

    public function destroy(int $id)
    {
        $midwife = Midwife::find($id);

        if (! $midwife) {
            return $this->fail('Bidan tidak ditemukan', 404, 'not_found');
        }

        if ($midwife->photo_path) {
            Storage::disk('media')->delete($midwife->photo_path);
        }

        $midwife->delete();

        return $this->ok(null, 'Bidan dihapus');
    }

    private function validated(Request $request): array
    {
        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:150'],
            'role' => ['sometimes', 'required', 'in:Bidan Koordinator,Bidan Pelaksana,Bidan'],
            'phone' => ['sometimes', 'required', 'string', 'max:30'],
            'alt_phone' => ['nullable', 'string', 'max:30'],
            'duty_hours_start' => ['nullable', 'date_format:H:i'],
            'duty_hours_end' => ['nullable', 'date_format:H:i'],
            'workdays' => ['nullable', 'array'],
            'workdays.*' => ['distinct', 'in:Senin,Selasa,Rabu,Kamis,Jumat,Sabtu,Minggu'],
            'photo' => ['nullable', 'image', 'mimes:jpeg,jpg,png,webp', 'max:2048'],
            'remove_photo' => ['nullable', 'boolean'],
            'is_active' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string'],
        ]);

        unset($data['duty_hours_start'], $data['duty_hours_end'], $data['photo'], $data['remove_photo']);

        return $data;
    }

    private function dutyHours(Request $request): ?string
    {
        $start = $request->input('duty_hours_start');
        $end = $request->input('duty_hours_end');

        return $start && $end ? "{$start}-{$end}" : null;
    }
}
