import AdminLayout from '../../Layouts/AdminLayout';
import { Link } from '@inertiajs/react';
import PageHeader from '../../components/PageHeader';
import {
    ArrowLeftIcon,
    ActivityIcon,
    BabyIcon,
    ClipboardIcon,
    EyeIcon,
    HeartPulseIcon,
    HistoryIcon,
    RefreshIcon,
} from '../../components/icons';

const riskBadge = {
    low: ['badge--success', 'Rendah'],
    medium: ['badge--warning', 'Sedang'],
    high: ['badge--danger', 'Tinggi'],
};

const bpColor = {
    green: 'indicator--success',
    yellow: 'indicator--warning',
    red: 'indicator--danger',
};

function Detail({ label, value }) {
    return (
        <div className="flex flex-col gap-1">
            <span className="text-sm text-muted-foreground">{label}</span>
            <span className="font-medium">{value ?? '-'}</span>
        </div>
    );
}

function SectionCard({ title, description, children }) {
    return (
        <section className="page__section">
            <div className="page__section-header">
                <div className="page__section-heading">
                    <h2 className="page__section-title">{title}</h2>
                    {description && <p className="page__section-description">{description}</p>}
                </div>
            </div>
            <div className="card">
                <div className="card__body">{children}</div>
            </div>
        </section>
    );
}

function EmptyRow({ label }) {
    return <p className="text-sm text-muted-foreground py-4 text-center">{label}</p>;
}

export default function PatientsShow({ patient, counts, bp_records, symptom_checks, kick_counts, anc_checks, sync_logs }) {
    const [badgeTone, badgeLabel] = riskBadge[patient.risk_level] ?? ['badge--neutral', patient.risk_level ?? '-'];

    return (
        <AdminLayout>
            <PageHeader
                title={patient.name}
                description={`${patient.age ?? '-'} tahun · kehamilan ${patient.gestational_weeks ?? '-'} minggu`}
            >
                <Link href="/patients" className="button button--ghost button--neutral">
                    <ArrowLeftIcon />
                    Kembali
                </Link>
            </PageHeader>

            <section className="page__section">
                <div className="card">
                    <div className="card__header">
                        <div className="card__heading">
                            <h2 className="card__title">Profil Pasien</h2>
                        </div>
                        <span className={`badge badge--soft ${badgeTone}`}>{badgeLabel}</span>
                    </div>
                    <div className="card__body">
                        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                            <Detail label="Umur" value={`${patient.age ?? '-'} tahun`} />
                            <Detail label="Tinggi" value={patient.height_cm != null ? `${patient.height_cm} cm` : null} />
                            <Detail label="Berat" value={patient.weight_kg != null ? `${patient.weight_kg} kg` : null} />
                            <Detail label="Usia Kehamilan" value={patient.gestational_weeks != null ? `${patient.gestational_weeks} minggu` : null} />
                            <Detail label="HPL" value={patient.due_date} />
                            <Detail label="Riwayat" value={patient.history_type} />
                            <Detail label="Telepon" value={patient.phone} />
                            <Detail label="Device" value={patient.device_uuid} />
                        </div>
                    </div>
                </div>
            </section>

            <section className="page__section">
                <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                    {[
                        { label: 'Catatan Tekanan Darah', value: counts.bp, Icon: HeartPulseIcon },
                        { label: 'Pemeriksaan Gejala', value: counts.symptom, Icon: ClipboardIcon },
                        { label: 'Hitung Gerakan Janin', value: counts.kick, Icon: BabyIcon },
                        { label: 'Kunjungan ANC', value: counts.anc, Icon: ActivityIcon },
                    ].map(({ label, value, Icon }) => (
                        <div key={label} className="card card--stat">
                            <div className="card__body">
                                <div className="flex items-center justify-between">
                                    <span className="icon-box icon-box--info icon-box--lg">
                                        <Icon />
                                    </span>
                                    <span className="stat__label text-eyebrow">{label}</span>
                                </div>
                                <div className="stat">
                                    <div className="stat__value">{value}</div>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </section>

            <SectionCard title="Catatan Tekanan Darah" description="30 pengukuran terakhir dari perangkat.">
                {bp_records.length === 0 ? (
                    <EmptyRow label="Belum ada catatan tekanan darah." />
                ) : (
                    <div className="table-responsive">
                        <table className="table table--hover">
                            <thead>
                                <tr>
                                    <th>Waktu</th>
                                    <th>Sesi</th>
                                    <th>Pengukuran 1</th>
                                    <th>Pengukuran 2</th>
                                    <th>Rata-rata</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                {bp_records.map((b) => (
                                    <tr key={b.uuid}>
                                        <td className="text-muted-foreground">{b.measured_at}</td>
                                        <td className="font-mono text-xs">{b.session_code}</td>
                                        <td>
                                            {b.systolic_1}/{b.diastolic_1}
                                        </td>
                                        <td>
                                            {b.systolic_2 != null ? `${b.systolic_2}/${b.diastolic_2}` : '-'}
                                        </td>
                                        <td className="font-medium">
                                            {b.avg_systolic}/{b.avg_diastolic}
                                        </td>
                                        <td>
                                            <span className="inline-flex items-center gap-2">
                                                <span className={`indicator ${bpColor[b.status_color] ?? 'indicator--neutral'}`} />
                                                <span className="text-sm">{b.status_color}</span>
                                            </span>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </SectionCard>

            <SectionCard title="Pemeriksaan Gejala" description="Gejala preeklampsia yang dilaporkan pasien.">
                {symptom_checks.length === 0 ? (
                    <EmptyRow label="Belum ada pemeriksaan gejala." />
                ) : (
                    <div className="table-responsive">
                        <table className="table table--hover">
                            <thead>
                                <tr>
                                    <th>Waktu</th>
                                    <th>Sakit Kepala</th>
                                    <th>Penglihatan Kabur</th>
                                    <th>Nyeri Ulu Hati</th>
                                    <th>Sesak Napas</th>
                                </tr>
                            </thead>
                            <tbody>
                                {symptom_checks.map((s) => (
                                    <tr key={s.uuid}>
                                        <td className="text-muted-foreground">{s.checked_at}</td>
                                        {[
                                            ['headache', s.headache],
                                            ['blurred_vision', s.blurred_vision],
                                            ['epigastric_pain', s.epigastric_pain],
                                            ['shortness_of_breath', s.shortness_of_breath],
                                        ].map(([name, v]) => (
                                            <td key={name}>
                                                <span
                                                    className={`badge badge--soft ${v ? 'badge--danger' : 'badge--success'}`}
                                                >
                                                    {v ? 'Ya' : 'Tidak'}
                                                </span>
                                            </td>
                                        ))}
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </SectionCard>

            <SectionCard title="Hitung Gerakan Janin" description="Sesi penghitungan gerakan janin.">
                {kick_counts.length === 0 ? (
                    <EmptyRow label="Belum ada sesi hitung gerakan." />
                ) : (
                    <div className="table-responsive">
                        <table className="table table--hover">
                            <thead>
                                <tr>
                                    <th>Dimulai</th>
                                    <th>Jumlah Gerakan</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                {kick_counts.map((k) => (
                                    <tr key={k.uuid}>
                                        <td className="text-muted-foreground">{k.started_at}</td>
                                        <td className="font-medium">{k.kick_count}</td>
                                        <td>
                                            <span
                                                className={`badge badge--soft ${k.is_active ? 'badge--success' : 'badge--neutral'}`}
                                            >
                                                {k.is_active ? 'Berjalan' : 'Selesai'}
                                            </span>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </SectionCard>

            <SectionCard title="Kunjungan ANC" description="Riwayat kunjungan antenatal.">
                {anc_checks.length === 0 ? (
                    <EmptyRow label="Belum ada kunjungan ANC." />
                ) : (
                    <div className="table-responsive">
                        <table className="table table--hover">
                            <thead>
                                <tr>
                                    <th>Tanggal Kunjungan</th>
                                    <th>Item Pemeriksaan</th>
                                </tr>
                            </thead>
                            <tbody>
                                {anc_checks.map((a) => (
                                    <tr key={a.uuid}>
                                        <td className="text-muted-foreground">{a.visited_at}</td>
                                        <td>{a.t_items_count} item</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </SectionCard>

            <SectionCard title="Riwayat Sinkronisasi" description="Status sinkronisasi data dari perangkat.">
                {sync_logs.length === 0 ? (
                    <EmptyRow label="Belum ada riwayat sinkronisasi." />
                ) : (
                    <div className="table-responsive">
                        <table className="table table--hover">
                            <thead>
                                <tr>
                                    <th>Status</th>
                                    <th>Records</th>
                                    <th>Waktu</th>
                                </tr>
                            </thead>
                            <tbody>
                                {sync_logs.map((s) => (
                                    <tr key={s.id}>
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
            </SectionCard>

            <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <RefreshIcon />
                <span>Data terakhir diperbarui saat perangkat melakukan sinkronisasi.</span>
            </div>
        </AdminLayout>
    );
}
