import AdminLayout from '../Layouts/AdminLayout';
import { Link, usePage } from '@inertiajs/react';
import PageHeader from '../components/PageHeader';
import {
    ActivityIcon,
    AlertIcon,
    BabyIcon,
    ClipboardIcon,
    HeartPulseIcon,
    RefreshIcon,
    UsersIcon,
} from '../components/icons';

const riskLabel = { low: 'Rendah', medium: 'Sedang', high: 'Tinggi' };
const riskTone = { low: 'badge--success', medium: 'badge--warning', high: 'badge--danger' };

export default function Dashboard({ stats, attention_patients, recent_syncs }) {
    const { auth } = usePage().props;
    const firstName = (auth?.user?.name || '').split(' ')[0] || 'Admin';
    const atRisk = stats.risk_at_risk ?? (stats.risk_medium ?? 0) + (stats.risk_high ?? 0);

    const cards = [
        {
            label: 'Pasien',
            value: stats.synced_patients,
            sub: `${atRisk} perlu perhatian`,
            Icon: UsersIcon,
            tone: 'primary',
            href: '/patients',
        },
        {
            label: 'Risiko sedang/tinggi',
            value: atRisk,
            sub: `Tinggi ${stats.risk_high ?? 0} · Sedang ${stats.risk_medium ?? 0}`,
            Icon: AlertIcon,
            tone: atRisk > 0 ? 'warning' : 'success',
            href: '/patients?risk=medium',
        },
        {
            label: 'TD perlu perhatian',
            value: stats.bp_alerts ?? 0,
            sub: `${stats.bp_patients ?? 0} pasien`,
            Icon: HeartPulseIcon,
            tone: (stats.bp_alerts ?? 0) > 0 ? 'danger' : 'neutral',
            href: '/patients',
        },
        {
            label: 'Gejala bahaya',
            value: stats.symptom_alerts ?? 0,
            sub: `${stats.symptom_patients ?? 0} pasien · perlu rujukan`,
            Icon: ClipboardIcon,
            tone: (stats.symptom_alerts ?? 0) > 0 ? 'danger' : 'neutral',
            href: '/patients',
        },
        {
            label: 'Sinkron 7 hari',
            value: stats.sync_7d ?? stats.sync_count_24h ?? 0,
            sub: 'aktivitas perangkat',
            Icon: RefreshIcon,
            tone: 'primary',
            href: '/sync-logs',
        },
    ];

    return (
        <AdminLayout>
            <PageHeader
                title={`Selamat datang kembali, ${firstName}`}
                description="Ringkasan pasien yang perlu perhatian dan aktivitas sinkronisasi."
            />

            <section className="page__section">
                <div className="grid grid-cols-12 gap-4">
                    {cards.map(({ label, value, sub, Icon, tone, href }) => (
                        <Link
                            key={label}
                            href={href}
                            className="col-span-12 sm:col-span-6 xl:col-span-4 no-underline"
                        >
                            <div className="card card--stat hover:shadow-sm transition-shadow">
                                <div className="card__body">
                                    <div className="flex items-center justify-between">
                                        <span className={`icon-box icon-box--${tone} icon-box--lg`}>
                                            <Icon />
                                        </span>
                                        <span className="stat__label text-eyebrow">{label}</span>
                                    </div>
                                    <div className="stat">
                                        <div className="stat__value">{value ?? 0}</div>
                                        {sub && <div className="text-xs text-muted-foreground mt-1">{sub}</div>}
                                    </div>
                                </div>
                            </div>
                        </Link>
                    ))}
                </div>
            </section>

            <section className="page__section">
                <div className="card">
                    <div className="card__header">
                        <div className="card__heading">
                            <h2 className="card__title">Pasien Perlu Perhatian</h2>
                            <p className="text-sm text-muted-foreground">
                                Risiko sedang/tinggi atau ada sinyal TD/gejala bahaya.
                            </p>
                        </div>
                        <Link href="/patients" className="button button--ghost button--sm">
                            Lihat semua
                        </Link>
                    </div>
                    <div className="card__body">
                        {!attention_patients || attention_patients.length === 0 ? (
                            <div className="empty-state">
                                <BabyIcon />
                                <p className="empty-state__title">Tidak ada pasien perlu perhatian</p>
                                <p className="empty-state__description">
                                    Semua pasien berisiko rendah dan tanpa sinyal bahaya.
                                </p>
                            </div>
                        ) : (
                            <div className="table-responsive">
                                <table className="table table--hover">
                                    <thead>
                                        <tr>
                                            <th>Pasien</th>
                                            <th>Risiko</th>
                                            <th>Sinyal</th>
                                            <th>Update</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {attention_patients.map((p) => (
                                            <tr key={p.uuid}>
                                                <td>
                                                    <Link href={`/patients/${p.uuid}`} className="link font-medium">
                                                        {p.name}
                                                    </Link>
                                                    <span className="text-xs text-muted-foreground ml-2">
                                                        {p.age ? `${p.age} th` : ''} {p.gestational_weeks ? `· ${p.gestational_weeks} mg` : ''}
                                                    </span>
                                                </td>
                                                <td>
                                                    <span className={`badge badge--soft ${riskTone[p.risk_level] ?? 'badge--neutral'}`}>
                                                        {riskLabel[p.risk_level] ?? p.risk_level ?? '-'}
                                                    </span>
                                                </td>
                                                <td>
                                                    <div className="flex gap-1 flex-wrap">
                                                        {p.has_bp_alert && <span className="badge badge--soft badge--danger text-xs">TD</span>}
                                                        {p.has_symptom_alert && <span className="badge badge--soft badge--danger text-xs">Gejala</span>}
                                                        {!p.has_bp_alert && !p.has_symptom_alert && <span className="badge badge--soft badge--warning text-xs">Risiko</span>}
                                                    </div>
                                                </td>
                                                <td className="text-muted-foreground text-sm">{p.updated_at}</td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </div>
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
                                    Data pasien akan muncul di sini setelah perangkat pertama kali sinkron.
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
