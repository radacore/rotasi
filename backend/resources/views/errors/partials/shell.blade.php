<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" data-theme="light">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">

        <script>
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
        <link
            rel="icon"
            type="image/svg+xml"
            href='data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><rect fill="%230a0a0a" width="512" height="512" rx="112"/><path stroke="%23fafafa" fill="none" stroke-width="76" stroke-linecap="round" d="M 392 144 H 200 A 56 56 0 0 0 200 256 H 312 A 56 56 0 0 1 312 368 H 120"/></svg>'
        >

        <title>{{ $title }} — {{ config('app.name', 'ROTASI') }}</title>

        @vite(['resources/css/app.css'])
    </head>
    <body
        class="flex min-h-dvh items-center justify-center p-6"
        style="background: var(--color-background); color: var(--color-foreground); font-family: var(--font-sans)"
    >
        <div class="card w-full max-w-md">
            <div class="card__body flex flex-col items-center gap-2 text-center">
                <span class="flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/10 text-primary">
                    <svg aria-hidden="true" width="2.5rem" height="2.5rem" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12 1.5l3.4 7.1 7.1 3.4-7.1 3.4-3.4 7.1-3.4-7.1L1.5 12l7.1-3.4z" opacity=".45" />
                        <path d="M12 1.5l3.4 7.1L12 12 8.6 8.6z" />
                    </svg>
                </span>

                <div class="mt-4 text-6xl font-bold tracking-tight">{{ $code }}</div>
                <h1 class="page__title">{{ $title }}</h1>
                <p class="text-sm text-muted-foreground">{{ $description }}</p>

                <div class="mt-6 flex flex-wrap items-center justify-center gap-2">
                    <a href="{{ url('/dashboard') }}" class="button button--primary">Ke Dashboard</a>
                    <button type="button" onclick="history.back()" class="button button--ghost button--neutral">
                        Kembali
                    </button>
                </div>
            </div>
        </div>
    </body>
</html>
