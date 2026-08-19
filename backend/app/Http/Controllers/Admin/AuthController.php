<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        if (! Auth::guard('web')->attempt($data)) {
            return $this->fail('Kredensial tidak valid', 401, 'invalid_credentials');
        }

        /** @var User $user */
        $user = Auth::guard('web')->user();
        $token = $user->createToken('admin')->plainTextToken;

        return $this->ok([
            'token' => $token,
            'user' => ['id' => $user->id, 'name' => $user->name, 'email' => $user->email],
        ], 'Login berhasil');
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return $this->ok(null, 'Logout berhasil');
    }

    public function user(Request $request)
    {
        /** @var User $user */
        $user = $request->user();

        return $this->ok([
            'user' => ['id' => $user->id, 'name' => $user->name, 'email' => $user->email],
        ], 'Admin saat ini');
    }
}
