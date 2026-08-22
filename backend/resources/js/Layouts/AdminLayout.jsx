import { useEffect, useRef, useState } from 'react';
import { Link, useForm, usePage } from '@inertiajs/react';
import useTheme from '../hooks/useTheme';
import useNavigation from '../hooks/useNavigation';
import ToastProvider from '../components/Toasts';
import PageSkeleton from '../components/PageSkeleton';
import {
    BoxIcon,
    DashboardIcon,
    GearIcon,
    HeartPulseIcon,
    LogoutIcon,
    MenuIcon,
    MoonIcon,
    ChevronDownIcon,
    RefreshIcon,
    SunIcon,
    UserIcon,
} from '../components/icons';

const navGroups = [
    {
        title: 'Utama',
        items: [
            { href: '/dashboard', label: 'Dashboard', Icon: DashboardIcon },
            { href: '/booklet', label: 'Booklet', Icon: BoxIcon },
            { href: '/midwives', label: 'Bidan', Icon: UserIcon },
        ],
    },
    {
        title: 'Data',
        items: [
            { href: '/patients', label: 'Pasien', Icon: HeartPulseIcon },
            { href: '/sync-logs', label: 'Sinkronisasi', Icon: RefreshIcon },
            { href: '/apk', label: 'Rilis APK', Icon: BoxIcon },
        ],
    },
];

const MOBILE = '(max-width: 63.99rem)';
const RAIL_BAND = '(min-width: 64rem) and (max-width: 79.99rem)';

export default function AdminLayout({ children }) {
    const { auth } = usePage().props;
    const { post } = useForm();
    const { theme, toggle } = useTheme();
    const loading = useNavigation();
    const [collapsed, setCollapsed] = useState(false);
    const [visible, setVisible] = useState(false);
    const [userOpen, setUserOpen] = useState(false);
    const userMenuRef = useRef(null);

    const url = usePage().url;

    const isMobile = () => window.matchMedia(MOBILE).matches;

    const toggleSidebar = () => {
        if (isMobile()) setVisible((v) => !v);
        else setCollapsed((c) => !c);
    };

    useEffect(() => {
        const railMql = window.matchMedia(RAIL_BAND);
        const mobileMql = window.matchMedia(MOBILE);

        const applyAutoCollapse = () => {
            if (railMql.matches) setCollapsed(true);
            else setCollapsed(false);
        };
        applyAutoCollapse();

        const onMobileChange = (e) => {
            if (!e.matches) setVisible(false);
        };
        mobileMql.addEventListener('change', onMobileChange);
        railMql.addEventListener('change', applyAutoCollapse);

        return () => {
            mobileMql.removeEventListener('change', onMobileChange);
            railMql.removeEventListener('change', applyAutoCollapse);
        };
    }, []);

    useEffect(() => {
        const onKey = (e) => {
            if (e.key === 'Escape') setVisible(false);
        };
        document.addEventListener('keydown', onKey);
        return () => document.removeEventListener('keydown', onKey);
    }, []);

    useEffect(() => {
        const onPointerDown = (e) => {
            if (userMenuRef.current && !userMenuRef.current.contains(e.target)) {
                setUserOpen(false);
            }
            if (
                visible &&
                e.target.closest('[data-stisla-app-shell].is-sidebar-visible') &&
                !e.target.closest('.sidebar') &&
                !e.target.closest('[data-stisla-app-shell-toggle]')
            ) {
                setVisible(false);
            }
        };
        document.addEventListener('mousedown', onPointerDown);
        return () => document.removeEventListener('mousedown', onPointerDown);
    }, [visible]);

    const logout = (e) => {
        e.preventDefault();
        post('/logout');
    };

    const isActive = (href) => url === href || url.startsWith(`${href}/`);

    return (
        <div
            className={`app-shell${collapsed ? ' is-sidebar-collapsed' : ''}${visible ? ' is-sidebar-visible' : ''}`}
            data-stisla-app-shell
            data-stisla-app-shell-auto-collapse="true"
        >
            <aside
                className="sidebar sidebar--lg sidebar--app"
                data-stisla-sidebar
                data-collapsed={collapsed ? '' : undefined}
            >
                <header className="sidebar__header">
                    <Link className="sidebar__brand flex items-center gap-2.5" href="/dashboard" aria-label="ROTASI — Roda Pantau Tensi">
                        <img
                            src="/logo-72.png"
                            srcSet="/logo-72.png 1x, /logo-140.png 2x"
                            alt="ROTASI"
                            className="h-8 w-8 shrink-0 object-contain"
                            width="32"
                            height="32"
                            loading="eager"
                            decoding="async"
                        />
                        <span className="flex flex-col leading-none">
                            <span className="text-[15px] font-bold tracking-[0.14em]">ROTASI</span>
                            <span className="text-[10px] font-medium tracking-wide text-muted-foreground">Roda Pantau Tensi</span>
                        </span>
                    </Link>
                </header>

                <div className="sidebar__content">
                    <nav className="sidebar__menu">
                        {navGroups.map((group) => (
                            <div key={group.title} className="sidebar__group">
                                <span className="sidebar__group-title">{group.title}</span>
                                <ul className="sidebar__list">
                                    {group.items.map(({ href, label, Icon }) => (
                                        <li key={href} className="sidebar__item">
                                            <Link
                                                className="sidebar__button"
                                                href={href}
                                                aria-current={isActive(href) ? 'page' : undefined}
                                            >
                                                <Icon />
                                                <span>{label}</span>
                                            </Link>
                                        </li>
                                    ))}
                                </ul>
                            </div>
                        ))}
                    </nav>
                </div>

                <footer className="sidebar__footer">
                    <ul className="sidebar__list">
                        <li className="sidebar__item">
                            <Link
                                className="sidebar__button"
                                href="/settings"
                                aria-current={isActive('/settings') ? 'page' : undefined}
                            >
                                <GearIcon />
                                <span>Pengaturan</span>
                            </Link>
                        </li>
                        <li className="sidebar__item">
                            <form onSubmit={logout}>
                                <button type="submit" className="sidebar__button">
                                    <LogoutIcon />
                                    <span>Keluar</span>
                                </button>
                            </form>
                        </li>
                    </ul>
                </footer>
            </aside>

            <main className="app-shell__main">
                <header className="navbar">
                    <button
                        type="button"
                        className="button button--ghost button--neutral button--icon-only button--flush-start"
                        data-stisla-app-shell-toggle="auto"
                        aria-label="Toggle sidebar"
                        aria-expanded={isMobile() ? visible : !collapsed}
                        onClick={toggleSidebar}
                    >
                        <MenuIcon />
                    </button>

                    <div className="ms-auto">
                        <div className="flex gap-1">
                            <button
                                type="button"
                                className="button button--ghost button--neutral button--icon-only"
                                data-theme-toggle
                                aria-label="Toggle theme"
                                onClick={toggle}
                            >
                                {theme === 'dark' ? <SunIcon /> : <MoonIcon />}
                            </button>

                            <div className="menu" ref={userMenuRef}>
                                <button
                                    type="button"
                                    className="button button--ghost button--neutral flex items-center gap-2"
                                    aria-haspopup="menu"
                                    aria-expanded={userOpen}
                                    onClick={() => setUserOpen((o) => !o)}
                                >
                                    <span className="hidden sm:inline font-medium">
                                        {auth?.user?.name}
                                    </span>
                                    <span className="avatar avatar--sm avatar--circle" data-stisla-avatar>
                                        <span className="avatar__fallback">
                                            {(auth?.user?.name || 'A').charAt(0).toUpperCase()}
                                        </span>
                                    </span>
                                    <ChevronDownIcon />
                                </button>
                                <div
                                    className="menu__popup w-52"
                                    role="menu"
                                    data-state={userOpen ? 'open' : 'closed'}
                                    style={{
                                        position: 'absolute',
                                        top: 'calc(100% + 0.5rem)',
                                        right: 0,
                                        left: 'auto',
                                    }}
                                >
                                    <div className="menu__group">
                                        <h3 className="menu__group-label">{auth?.user?.email}</h3>
                                        <Link href="/account" className="menu__item" role="menuitem">
                                            <UserIcon />
                                            Profil
                                        </Link>
                                        <Link href="/settings" className="menu__item" role="menuitem">
                                            <GearIcon />
                                            Pengaturan
                                        </Link>
                                    </div>
                                    <hr className="menu__separator" />
                                    <form onSubmit={logout}>
                                        <button type="submit" className="menu__item w-full" role="menuitem">
                                            <LogoutIcon />
                                            Keluar
                                        </button>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                </header>

                <div className="page content">
                    <div className="content__container">
                        {loading ? (
                            <PageSkeleton />
                        ) : (
                            <ToastProvider>{children}</ToastProvider>
                        )}
                    </div>
                </div>
            </main>
        </div>
    );
}
