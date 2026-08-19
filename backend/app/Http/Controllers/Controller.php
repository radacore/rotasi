<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Routing\Controller as BaseController;

class Controller extends BaseController
{
    use AuthorizesRequests;
    use ValidatesRequests;

    protected function ok(mixed $data = null, string $message = 'OK', int $code = 200): \Illuminate\Http\JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $data,
            'message' => $message,
        ], $code);
    }

    protected function fail(string $message, int $code = 400, ?string $error = null): \Illuminate\Http\JsonResponse
    {
        return response()->json([
            'success' => false,
            'error' => $error,
            'message' => $message,
        ], $code);
    }

    protected function paginated(\Illuminate\Contracts\Pagination\LengthAwarePaginator $items, string $message = 'OK'): \Illuminate\Http\JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $items->items(),
            'message' => $message,
            'pagination' => [
                'current_page' => $items->currentPage(),
                'per_page' => $items->perPage(),
                'total' => $items->total(),
                'last_page' => $items->lastPage(),
                'from' => $items->firstItem(),
                'to' => $items->lastItem(),
            ],
        ]);
    }
}
