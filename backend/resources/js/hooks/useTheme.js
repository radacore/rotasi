import { useCallback, useState } from 'react';

export default function useTheme() {
    const [theme, setTheme] = useState(() => document.documentElement.dataset.theme || 'light');

    const toggle = useCallback(() => {
        setTheme((current) => {
            const next = current === 'dark' ? 'light' : 'dark';
            document.documentElement.dataset.theme = next;
            localStorage.setItem('stisla-theme', next);
            return next;
        });
    }, []);

    return { theme, toggle };
}
