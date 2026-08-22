import { useState } from 'react';
import { useForm } from '@inertiajs/react';
import useTheme from '../../hooks/useTheme';
import { EyeIcon, MailIcon, MoonIcon, SunIcon } from '../../components/icons';

export default function Login() {
    const { data, setData, post, processing, errors } = useForm({
        email: '',
        password: '',
    });
    const { theme, toggle } = useTheme();
    const [show, setShow] = useState(false);

    const submit = (e) => {
        e.preventDefault();
        post('/login');
    };

    return (
        <main className="auth auth--centered">
            <section className="auth__panel">
                <button
                    type="button"
                    className="button button--ghost button--neutral button--icon-only auth__toggle"
                    data-theme-toggle
                    aria-label="Toggle theme"
                    onClick={toggle}
                >
                    {theme === 'dark' ? <SunIcon /> : <MoonIcon />}
                </button>

                <div className="auth__form">
                    <div className="flex flex-col items-center text-center gap-2">
                        <img
                            src="/logo-180.png"
                            srcSet="/logo-180.png 1x, /logo-256.png 2x"
                            alt="ROTASI"
                            className="h-20 w-auto object-contain"
                            width="180"
                            height="180"
                            loading="eager"
                            decoding="async"
                        />
                        <div className="flex flex-col items-center gap-1">
                            <p className="text-[15px] font-bold tracking-[0.18em]">ROTASI</p>
                            <p className="text-xs font-medium tracking-wide text-muted-foreground">Roda Pantau Tensi</p>
                        </div>
                        <div className="pt-1">
                            <h1 className="text-2xl">Selamat datang kembali</h1>
                            <p className="text-muted-foreground mt-1">
                                Masuk ke dashboard admin ROTASI.
                            </p>
                        </div>
                    </div>

                    <form onSubmit={submit} className="flex flex-col gap-4">
                        <div className="field">
                            <label htmlFor="email" className="field__label">
                                Email
                            </label>
                            <div className="input-group input-group--lg">
                                <span className="input-group__text">
                                    <MailIcon />
                                </span>
                                <input
                                    id="email"
                                    type="email"
                                    className="input"
                                    placeholder="admin@rotasi.test"
                                    autoComplete="email"
                                    value={data.email}
                                    onChange={(e) => setData('email', e.target.value)}
                                />
                            </div>
                            {errors.email && <p className="field__error">{errors.email}</p>}
                        </div>

                        <div className="field">
                            <label htmlFor="password" className="field__label">
                                Password
                            </label>
                            <div className="input-group input-group--lg">
                                <span className="input-group__text">
                                    <svg aria-hidden="true" width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor">
                                        <g fill="none" stroke="currentColor" strokeWidth="1.5">
                                            <path d="M2 16c0-2.828 0-4.243.879-5.121C3.757 10 5.172 10 8 10h8c2.828 0 4.243 0 5.121.879C22 11.757 22 13.172 22 16s0 4.243-.879 5.121C20.243 22 18.828 22 16 22H8c-2.828 0-4.243 0-5.121-.879C2 20.243 2 18.828 2 16Z" />
                                            <circle cx="12" cy="16" r="2" />
                                            <path strokeLinecap="round" d="M6 10V8a6 6 0 1 1 12 0v2" />
                                        </g>
                                    </svg>
                                </span>
                                <input
                                    id="password"
                                    type={show ? 'text' : 'password'}
                                    className="input"
                                    placeholder="••••••••••"
                                    autoComplete="current-password"
                                    value={data.password}
                                    onChange={(e) => setData('password', e.target.value)}
                                />
                                <button
                                    type="button"
                                    className="input-group__text"
                                    data-password-toggle
                                    aria-controls="password"
                                    aria-label="Show password"
                                    aria-pressed={show}
                                    onClick={() => setShow((s) => !s)}
                                >
                                    <EyeIcon />
                                </button>
                            </div>
                            {errors.password && <p className="field__error">{errors.password}</p>}
                        </div>

                        <button
                            type="submit"
                            className="button button--primary button--block button--lg"
                            disabled={processing}
                        >
                            Masuk
                        </button>
                    </form>
                </div>
            </section>
        </main>
    );
}
