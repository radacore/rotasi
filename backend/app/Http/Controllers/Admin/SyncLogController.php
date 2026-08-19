<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SyncLog;
use Illuminate\Http\Request;

class SyncLogController extends Controller
{
    public function index(Request $request)
    {
        $query = SyncLog::query()->orderByDesc('id');

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        $perPage = min((int) $request->query('per_page', 20), 100);
        $items = $query->paginate($perPage);

        return $this->paginated($items, 'Daftar log sinkronisasi');
    }
}
