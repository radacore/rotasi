import { useEffect, useRef, useState } from 'react';
import AdminLayout from '../../Layouts/AdminLayout';
import { Link, router, useForm } from '@inertiajs/react';
import PageHeader from '../../components/PageHeader';
import Pagination from '../../components/Pagination';
import ConfirmDialog from '../../components/ConfirmDialog';
import { useToast } from '../../components/Toasts';
import { HeartPulseIcon, EyeIcon, SearchIcon, TrashIcon } from '../../components/icons';

const riskBadge = {
    unknown: ['badge--neutral', 'Belum dinilai'],
    low: ['badge--success', 'Rendah'],
    medium: ['badge--warning', 'Sedang'],
    high: ['badge--danger', 'Tinggi'],
};

export default function PatientsIndex({ patients, filters }) {
    const toast = useToast();
    const [search, setSearch] = useState(filters.search ?? '');
    const searchRef = useRef(null);
    const [confirmTarget, setConfirmTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);
    const { delete: destroy } = useForm();

    useEffect(() => {
        return () => clearTimeout(searchRef.current);
    }, []);

    const filterRisk = (value) => {
        router.get('/patients', { search: filters.search ?? '', risk: value }, { preserveState: true, replace: true });
    };

    const onSearchChange = (value) => {
        setSearch(value);
        clearTimeout(searchRef.current);
        searchRef.current = setTimeout(() => {
            router.get('/patients', { search: value, risk: filters.risk ?? '' }, { preserveState: true, replace: true });
        }, 300);
    };

    const remove = (uuid, name) => setConfirmTarget({ uuid, name });

    const handleConfirmDelete = () => {
        setDeleting(true);
        destroy(`/patients/${confirmTarget.uuid}`, {
            onSuccess: () => toast('Pasien dihapus.'),
            onError: () => toast('Gagal menghapus pasien.', 'danger'),
            onFinish: () => {
                setDeleting(false);
                setConfirmTarget(null);
            },
        });
    };

    return (
        <AdminLayout>
            <PageHeader
                title="Data Pasien"
                description="Daftar pasien yang tersinkron dari perangkat bidan."
            />

            <section className="page__section">
                <div className="card">
                    <div className="card__header">
                        <div className="flex flex-wrap items-center gap-3">
                            <div className="flex items-center gap-3 flex-1 min-w-[220px]">
                                <div className="input-group input-group--sm flex-1">
                                    <span className="input-group__text">
                                        <SearchIcon />
                                    </span>
                                    <input
                                        type="search"
                                        className="input input--seamless"
                                        placeholder="Cari nama..."
                                        value={search}
                                        onChange={(e) => onSearchChange(e.target.value)}
                                    />
                                </div>
                                <select
                                    className="select select--sm w-44 shrink-0"
                                    value={filters.risk ?? ''}
                                    onChange={(e) => filterRisk(e.target.value)}
                                >
                                    <option value="">Semua risiko</option>
                                    <option value="unknown">Belum dinilai</option>
                                    <option value="low">Rendah</option>
                                    <option value="medium">Sedang</option>
                                    <option value="high">Tinggi</option>
                                </select>
                            </div>
                        </div>
                    </div>
                    <div className="card__body">
                        {patients.data.length === 0 ? (
                            <div className="empty-state">
                                <HeartPulseIcon />
                                <p className="empty-state__title">Belum ada pasien</p>
                                <p className="empty-state__description">
                                    Pasien akan muncul setelah sinkronisasi pertama dari perangkat.
                                </p>
                            </div>
                        ) : (
                            <div className="table-responsive">
                                <table className="table table--hover">
                                    <thead>
                                        <tr>
                                            <th>Nama</th>
                                            <th>Usia</th>
                                            <th>Usia Kehamilan</th>
                                            <th>Risiko</th>
                                            <th>Tekanan Terakhir</th>
                                            <th>Catatan</th>
                                            <th className="text-right">Aksi</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {patients.data.map((p) => {
                                            const [badgeTone, badgeLabel] = riskBadge[p.risk_level] ?? [
                                                'badge--neutral',
                                                p.risk_level ?? '-',
                                            ];
                                            return (
                                                <tr key={p.patient_uuid}>
                                                    <td className="font-medium">{p.name}</td>
                                                    <td>{p.age ?? '-'}</td>
                                                    <td>{p.gestational_weeks != null ? `${p.gestational_weeks} minggu` : '-'}</td>
                                                    <td>
                                                        <span className={`badge badge--soft ${badgeTone}`}>
                                                            {badgeLabel}
                                                        </span>
                                                    </td>
                                                    <td>
                                                        {p.latest_bp ? (
                                                            <span className="inline-flex items-center gap-2">
                                                                <span className="font-medium">
                                                                    {p.latest_bp.avg_systolic}/{p.latest_bp.avg_diastolic}
                                                                </span>
                                                                <span className="text-xs text-muted-foreground">
                                                                    mmHg
                                                                </span>
                                                            </span>
                                                        ) : (
                                                            <span className="text-xs text-muted-foreground" title="Belum ada pengukuran">
                                                                Belum ada pengukuran ({p.bp_count})
                                                            </span>
                                                        )}
                                                    </td>
                                                    <td>{p.bp_count}</td>
                                                    <td>
                                                        <div className="flex justify-end gap-1">
                                                            <Link
                                                                href={`/patients/${p.patient_uuid}`}
                                                                className="button button--sm button--ghost button--primary"
                                                            >
                                                                <EyeIcon />
                                                                Lihat
                                                            </Link>
                                                            <button
                                                                type="button"
                                                                onClick={() => remove(p.patient_uuid, p.name)}
                                                                className="button button--sm button--ghost button--danger"
                                                            >
                                                                <TrashIcon />
                                                                Hapus
                                                            </button>
                                                        </div>
                                                    </td>
                                                </tr>
                                            );
                                        })}
                                    </tbody>
                                </table>
                            </div>
                        )}
                        {patients.links && (
                            <Pagination meta={patients} />
                        )}
                    </div>
                </div>
            </section>

            <ConfirmDialog
                open={confirmTarget !== null}
                title="Hapus Pasien"
                message={
                    confirmTarget
                        ? `Data pasien "${confirmTarget.name}" beserta semua catatan (tensi, gejala, gerakan janin, ANC, log sinkronisasi) akan dihapus permanen. Lanjutkan?`
                        : ''
                }
                confirmLabel={deleting ? 'Menghapus...' : 'Hapus'}
                loading={deleting}
                onConfirm={handleConfirmDelete}
                onCancel={() => setConfirmTarget(null)}
            />
        </AdminLayout>
    );
}
