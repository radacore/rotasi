import { useEffect, useState } from 'react';
import { router } from '@inertiajs/react';

export default function useNavigation(delay = 250) {
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        let timer = null;

        const start = () => {
            clearTimeout(timer);
            timer = setTimeout(() => setLoading(true), delay);
        };

        const finish = () => {
            clearTimeout(timer);
            setLoading(false);
        };

        const offStart = router.on('start', start);
        const offFinish = router.on('finish', finish);

        return () => {
            clearTimeout(timer);
            offStart();
            offFinish();
        };
    }, [delay]);

    return loading;
}
