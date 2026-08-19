import { useEffect } from 'react';
import { createPortal } from 'react-dom';
import { AlertIcon, XIcon } from './icons';

export default function ConfirmDialog({
    open,
    title = 'Konfirmasi',
    message,
    confirmLabel = 'Hapus',
    cancelLabel = 'Batal',
    tone = 'danger',
    loading = false,
    onConfirm,
    onCancel,
}) {
    useEffect(() => {
        if (!open) return;

        const onKey = (e) => {
            if (e.key === 'Escape' && !loading) onCancel();
        };

        document.addEventListener('keydown', onKey);
        document.documentElement.setAttribute('data-dialog-open', '');

        return () => {
            document.removeEventListener('keydown', onKey);
            document.documentElement.removeAttribute('data-dialog-open');
        };
    }, [open, loading, onCancel]);

    if (!open) return null;

    return createPortal(
        <div
            className="dialog"
            data-state="open"
            role="dialog"
            aria-modal="true"
            aria-labelledby="confirm-dialog-title"
        >
            <div
                className="dialog__backdrop"
                role="presentation"
                aria-hidden="true"
                onClick={loading ? undefined : onCancel}
            />
            <div className="dialog__panel">
                <div className="dialog__content">
                    <button
                        type="button"
                        className="dialog__close"
                        onClick={onCancel}
                        disabled={loading}
                        aria-label="Tutup"
                    >
                        <XIcon />
                    </button>
                    <div className="dialog__header">
                        <h2 id="confirm-dialog-title" className="dialog__title">
                            {title}
                        </h2>
                    </div>
                    <div className="dialog__body">
                        <div className="flex items-start gap-3">
                            <span className="icon-box icon-box--danger icon-box--lg">
                                <AlertIcon />
                            </span>
                            <p className="text-sm text-muted-foreground">{message}</p>
                        </div>
                    </div>
                    <div className="dialog__footer">
                        <button
                            type="button"
                            className="button button--ghost button--neutral"
                            onClick={onCancel}
                            disabled={loading}
                        >
                            {cancelLabel}
                        </button>
                        <button
                            type="button"
                            className={tone === 'danger' ? 'button button--danger' : 'button button--primary'}
                            onClick={onConfirm}
                            disabled={loading}
                        >
                            {loading && <span className="spinner spinner--sm" />}
                            {confirmLabel}
                        </button>
                    </div>
                </div>
            </div>
        </div>,
        document.body,
    );
}
