<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" data-theme="light">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="csrf-token" content="{{ csrf_token() }}">

        <script>
            // Apply the saved theme before first paint to avoid a flash.
            (function () {
                var t = localStorage.getItem('stisla-theme');
                if (t === 'dark' || t === 'light') document.documentElement.dataset.theme = t;
            })();
        </script>

        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link
            href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
            rel="stylesheet"
        >
        <link rel="icon" href="/favicon.ico" sizes="32x32">
        <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
        <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">
        <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png">

        <title inertia>{{ config('app.name', 'ROTASI') }}</title>

        @vite(['resources/css/app.css', 'resources/js/app.jsx'])
    </head>
    <body>
        @inertia
    </body>
</html>
