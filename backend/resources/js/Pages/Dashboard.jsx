import AdminLayout from '../Layouts/AdminLayout';
import { usePage } from '@inertiajs/react';
import PageHeader from '../components/PageHeader';
import {
    ActivityIcon,
    BabyIcon,
    BoxIcon,
    HeartPulseIcon,
    ImageIcon,
    RefreshIcon,
} from '../components/icons';

const statCards = (stats) => [
    { label: 'Versi booklet aktif', value: stats.active_booklet_version, Icon: BoxIcon, tone: 'primary' },
    { label: 'Booklet diunggah', value: stats.booklet_releases, Icon: BoxIcon, tone: 'success' },
    { label: 'Rilis APK', value: stats.apk_releases, Icon: ImageIcon, tone: 'info' },
    { label: 'Pasien tersinkron', value: stats.synced_patients, Icon: HeartPulseIcon, tone: 'danger' },
    { label: 'Sinkron 24 jam', value: stats.sync_count_24h, Icon: RefreshIcon, tone: 'primary' },
];

export default function Dashboard({ stats, recent_syncs }) {
    const { auth } = usePage().props;
    const firstName = (auth?.user?.name || '').split(' ')[0] || 'Admin';

    return (
        <AdminLayout>
            <PageHeader
                title={`Selamat datang kembali, ${firstName}`}
                description="Ringkasan status booklet, rilis, dan sinkronisasi perangkat pasien."
            />

            <section className="page__section">
                <div className="grid grid-cols-12 gap-4">
                    {statCards(stats).map(({ label, value, Icon, tone }) => (
                        <div key={label} className="col-span-12 sm:col-span-6 xl:col-span-4">
                            <div className="card card--stat">
                                <div className="card__body">
                                    <div className="flex items-center justify-between">
                                        <span className={`icon-box icon-box--${tone} icon-box--lg`}>
                                            <Icon />
                                        </span>
                                        <span className="stat__label text-eyebrow">{label}</span>
                                    </div>
                                    <div className="stat">
                                        <div className="stat__value">{value ?? 0}</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </section>

            <section className="page__section">
                <div className="card">
                    <div className="card__header">
                        <div className="card__heading">
                            <h2 className="card__title">Sinkronisasi Terbaru</h2>
                        </div>
                    </div>
                    <div className="card__body">
                        {recent_syncs.length === 0 ? (
                            <div className="empty-state">
                                <BabyIcon />
                                <p className="empty-state__title">Belum ada sinkronisasi</p>
                                <p className="empty-state__description">
                                    Data pasien akan muncul di sini setelah perangkat bidan pertama kali sinkron.
                                </p>
                            </div>
                        ) : (
                            <div className="table-responsive">
                                <table className="table table--hover">
                                    <thead>
                                        <tr>
                                            <th>Device</th>
                                            <th>Status</th>
                                            <th>Records</th>
                                            <th>Waktu</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {recent_syncs.map((s) => (
                                            <tr key={s.id}>
                                                <td className="font-mono text-xs">{s.device_uuid}</td>
                                                <td>
                                                    <span
                                                        className={`badge badge--soft ${s.status === 'success' ? 'badge--success' : 'badge--danger'}`}
                                                    >
                                                        {s.status === 'success' ? 'Berhasil' : 'Gagal'}
                                                    </span>
                                                </td>
                                                <td>{s.records_count}</td>
                                                <td className="text-muted-foreground">{s.synced_at}</td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </div>
                </div>
            </section>

            <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <ActivityIcon />
                <span>Pantau berkala — pelaporan rutin membantu deteksi dini risiko kehamilan.</span>
            </div>
        </AdminLayout>
    );
}
