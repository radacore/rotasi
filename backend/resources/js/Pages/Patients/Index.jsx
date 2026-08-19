import AdminLayout from '../../Layouts/AdminLayout';
import { Link, router } from '@inertiajs/react';
import PageHeader from '../../components/PageHeader';
import Pagination from '../../components/Pagination';
import { HeartPulseIcon, EyeIcon } from '../../components/icons';

const riskBadge = {
    low: ['badge--success', 'Rendah'],
    medium: ['badge--warning', 'Sedang'],
    high: ['badge--danger', 'Tinggi'],
};

export default function PatientsIndex({ patients, filters }) {
    const filterRisk = (value) => {
        router.get('/patients', { risk: value }, { preserveState: true, replace: true });
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
                        <div className="flex items-center gap-3">
                            <select
                                className="select select--sm"
                                value={filters.risk ?? ''}
                                onChange={(e) => filterRisk(e.target.value)}
                            >
                                <option value="">Semua risiko</option>
                                <option value="low">Rendah</option>
                                <option value="medium">Sedang</option>
                                <option value="high">Tinggi</option>
                            </select>
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
                                                            '-'
                                                        )}
                                                    </td>
                                                    <td>{p.bp_count}</td>
                                                    <td>
                                                        <div className="flex justify-end">
                                                            <Link
                                                                href={`/patients/${p.patient_uuid}`}
                                                                className="button button--sm button--ghost button--primary"
                                                            >
                                                                <EyeIcon />
                                                                Lihat
                                                            </Link>
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
        </AdminLayout>
    );
}
