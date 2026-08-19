<?php

namespace App\Http\Middleware;

use App\Models\Device;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureDeviceAuth
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user instanceof Device) {
            return response()->json([
                'success' => false,
                'error' => 'unauthorized',
                'message' => 'Token perangkat tidak valid',
            ], 401);
        }

        return $next($request);
    }
}
