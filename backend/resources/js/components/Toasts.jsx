import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { usePage } from '@inertiajs/react';
import { AlertIcon, CheckIcon, XIcon } from './icons';

const ToastContext = createContext(() => {});

export const useToast = () => useContext(ToastContext);

let idSeq = 0;

const toastMeta = {
    success: { icon: CheckIcon, title: 'Berhasil' },
    danger: { icon: AlertIcon, title: 'Gagal' },
};

export default function ToastProvider({ children }) {
    const { flash } = usePage().props;
    const [toasts, setToasts] = useState([]);
    const lastFlash = useRef('');

    const dismiss = useCallback((id) => {
        setToasts((prev) => prev.filter((t) => t.id !== id));
    }, []);

    const push = useCallback(
        (type, message) => {
            const id = ++idSeq;
            setToasts((prev) => [...prev, { id, type, message }]);
            setTimeout(() => dismiss(id), 4500);
        },
        [dismiss],
    );

    const toast = useCallback(
        (message, type = 'success') => push(type, message),
        [push],
    );

    useEffect(() => {
        const key = JSON.stringify(flash ?? null);
        if (key === lastFlash.current) return;
        lastFlash.current = key;

        if (flash?.success) push('success', flash.success);
        if (flash?.error) push('danger', flash.error);
    }, [flash, push]);

    return (
        <ToastContext.Provider value={toast}>
            {children}
            {createPortal(
                <div className="toast-region toast-region--bottom-end" aria-live="polite" aria-atomic="false">
                    {toasts.map((t) => {
                        const { icon: Icon, title } = toastMeta[t.type] ?? toastMeta.success;
                        return (
                            <div key={t.id} className={`toast toast--${t.type}`} data-state="open">
                                <span className="toast__icon">
                                    <Icon />
                                </span>
                                <div className="toast__content">
                                    <p className="toast__header">{title}</p>
                                    <p className="toast__body">{t.message}</p>
                                </div>
                                <button
                                    type="button"
                                    className="toast__close"
                                    onClick={() => dismiss(t.id)}
                                    aria-label="Tutup"
                                >
                                    <XIcon />
                                </button>
                            </div>
                        );
                    })}
                </div>,
                document.body,
            )}
        </ToastContext.Provider>
    );
}
