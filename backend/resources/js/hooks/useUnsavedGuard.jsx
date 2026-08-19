import { useEffect, useRef, useState } from 'react';
import { router } from '@inertiajs/react';
import ConfirmDialog from '../components/ConfirmDialog';

export default function useUnsavedGuard(dirty, { message = 'Perubahan belum disimpan.' } = {}) {
    const [open, setOpen] = useState(false);
    const pending = useRef(null);
    const intentRef = useRef(false);
    const dirtyRef = useRef(dirty);
    dirtyRef.current = dirty;

    useEffect(() => {
        const onBefore = (event) => {
            if (intentRef.current || !dirtyRef.current) return;
            event.preventDefault();
            pending.current = event.detail.visit;
            setOpen(true);
        };

        const onFinish = () => {
            intentRef.current = false;
        };

        const offBefore = router.on('before', onBefore);
        const offFinish = router.on('finish', onFinish);

        const onUnload = (e) => {
            if (!dirtyRef.current) return;
            e.preventDefault();
            e.returnValue = '';
        };

        window.addEventListener('beforeunload', onUnload);

        return () => {
            offBefore();
            offFinish();
            window.removeEventListener('beforeunload', onUnload);
        };
    }, []);

    const markIntent = () => {
        intentRef.current = true;
    };

    const confirmLeave = () => {
        setOpen(false);
        intentRef.current = true;
        const visit = pending.current;
        pending.current = null;
        if (visit) {
            router.visit(visit.url, {
                method: visit.method,
                data: visit.data,
                ...visit.options,
            });
        }
    };

    const guardEl = (
        <ConfirmDialog
            open={open}
            title="Perubahan Belum Disimpan"
            message={message}
            confirmLabel="Tinggalkan"
            tone="primary"
            onConfirm={confirmLeave}
            onCancel={() => setOpen(false)}
        />
    );

    return { markIntent, guardEl };
}
