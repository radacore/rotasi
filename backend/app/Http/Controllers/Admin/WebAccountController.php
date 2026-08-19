<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class WebAccountController extends Controller
{
    public function edit()
    {
        return inertia('Account/Edit');
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'new_password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        if (! Hash::check($data['current_password'], $request->user()->password)) {
            return back()->withErrors(['current_password' => 'Password saat ini salah.']);
        }

        $request->user()->update([
            'password' => Hash::make($data['new_password']),
        ]);

        return redirect()->route('account.edit')->with('success', 'Password berhasil diubah.');
    }
}
