import { useEffect, useRef, useState } from 'react';
import AdminLayout from '../../Layouts/AdminLayout';
import { Link, router } from '@inertiajs/react';
import PageHeader from '../../components/PageHeader';
import Pagination from '../../components/Pagination';
import { RefreshIcon, SearchIcon } from '../../components/icons';

export default function SyncLogsIndex({ logs, filters }) {
    const [search, setSearch] = useState(filters.search ?? '');
    const debounceRef = useRef(null);

    useEffect(() => {
        return () => clearTimeout(debounceRef.current);
    }, []);

    const applyFilters = (overrides = {}) => {
        router.get(
            '/sync-logs',
            { ...filters, ...overrides },
            { preserveState: true, replace: true },
        );
    };

    const onSearchChange = (value) => {
        setSearch(value);
        clearTimeout(debounceRef.current);
        debounceRef.current = setTimeout(() => {
            router.get('/sync-logs', { ...filters, search: value }, { preserveState: true, replace: true });
        }, 300);
    };

    return (
        <AdminLayout>
            <PageHeader
                title="Riwayat Sinkronisasi"
                description="Catatan sinkronisasi data dari perangkat ke server."
            />

            <section className="page__section">
                <div className="card">
                    <div className="card__header">
                        <div className="flex flex-wrap items-center gap-3">
                            <div className="input-group input-group--sm w-56">
                                <span className="input-group__text">
                                    <SearchIcon />
                                </span>
                                <input
                                    type="search"
                                    className="input input--seamless"
                                    placeholder="Cari device atau pasien..."
                                    value={search}
                                    onChange={(e) => onSearchChange(e.target.value)}
                                />
                            </div>
                            <select
                                className="select select--sm w-40"
                                value={filters.status ?? ''}
                                onChange={(e) => applyFilters({ status: e.target.value })}
                            >
                                <option value="">Semua status</option>
                                <option value="success">Berhasil</option>
                                <option value="failed">Gagal</option>
                            </select>
                        </div>
                    </div>
                    <div className="card__body">
                        {logs.data.length === 0 ? (
                            <div className="empty-state">
                                <RefreshIcon />
                                <p className="empty-state__title">Tidak ada log</p>
                                <p className="empty-state__description">
                                    Tidak ada sinkronisasi yang cocok dengan filter.
                                </p>
                            </div>
                        ) : (
                            <div className="table-responsive">
                                <table className="table table--hover">
                                    <thead>
                                        <tr>
                                            <th>Waktu</th>
                                            <th>Device</th>
                                            <th>Pasien</th>
                                            <th>Status</th>
                                            <th>Records</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {logs.data.map((log) => (
                                            <tr key={log.id}>
                                                <td className="text-muted-foreground">{log.synced_at}</td>
                                                <td className="font-mono text-xs">{log.device_uuid}</td>
                                                <td>
                                                    {log.patient_uuid ? (
                                                        <Link
                                                            href={`/patients/${log.patient_uuid}`}
                                                            className="link"
                                                        >
                                                            {log.patient_name || log.patient_uuid}
                                                        </Link>
                                                    ) : (
                                                        '-'
                                                    )}
                                                </td>
                                                <td>
                                                    <span
                                                        className={`badge badge--soft ${log.status === 'success' ? 'badge--success' : 'badge--danger'}`}
                                                    >
                                                        {log.status === 'success' ? 'Berhasil' : 'Gagal'}
                                                    </span>
                                                </td>
                                                <td>{log.records_count}</td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                        {logs.links && (
                            <Pagination meta={logs} />
                        )}
                    </div>
                </div>
            </section>
        </AdminLayout>
    );
}
