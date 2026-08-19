import { useState } from 'react';
import AdminLayout from '../../Layouts/AdminLayout';
import { Link, useForm, router } from '@inertiajs/react';
import PageHeader from '../../components/PageHeader';
import Pagination from '../../components/Pagination';
import ConfirmDialog from '../../components/ConfirmDialog';
import { PencilIcon, PlusIcon, TrashIcon, UsersIcon } from '../../components/icons';

const initialsOf = (name) =>
    String(name || '')
        .trim()
        .split(/\s+/)
        .slice(0, 2)
        .map((word) => word[0])
        .join('')
        .toUpperCase() || '?';

export default function MidwivesIndex({ midwives, filters }) {
    const { delete: destroy } = useForm();
    const [confirmTarget, setConfirmTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);

    const remove = (id) => setConfirmTarget({ id });

    const handleConfirmDelete = () => {
        setDeleting(true);
        destroy(`/midwives/${confirmTarget.id}`, {
            onFinish: () => {
                setDeleting(false);
                setConfirmTarget(null);
            },
        });
    };

    const filterActive = (value) => {
        router.get('/midwives', { is_active: value }, { preserveState: true, replace: true });
    };

    return (
        <AdminLayout>
            <PageHeader
                title="Data Bidan"
                description="Daftar bidan yang menjadi petugas pelaporan."
            >
                <Link href="/midwives/create" className="button button--primary">
                    <PlusIcon />
                    Bidan Baru
                </Link>
            </PageHeader>

            <section className="page__section">
                <div className="card">
                    <div className="card__header">
                        <div className="flex items-center gap-3">
                            <select
                                className="select select--sm"
                                value={filters.is_active ?? ''}
                                onChange={(e) => filterActive(e.target.value)}
                            >
                                <option value="">Semua status</option>
                                <option value="1">Aktif</option>
                                <option value="0">Nonaktif</option>
                            </select>
                        </div>
                    </div>
                    <div className="card__body">
                        {midwives.data.length === 0 ? (
                            <div className="empty-state">
                                <UsersIcon />
                                <p className="empty-state__title">Belum ada bidan</p>
                                <p className="empty-state__description">
                                    Tambahkan bidan pertama untuk mulai mendata pelaporan.
                                </p>
                            </div>
                        ) : (
                            <div className="table-responsive">
                                <table className="table table--hover">
                                    <thead>
                                        <tr>
                                            <th>Foto</th>
                                            <th>Nama</th>
                                            <th>Telepon atau Nomor Whatsapp</th>
                                            <th>Status</th>
                                            <th className="text-right">Aksi</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {midwives.data.map((m) => (
                                            <tr key={m.id}>
                                                <td>
                                                    {m.photo_url ? (
                                                        <img
                                                            src={m.photo_url}
                                                            alt={m.name}
                                                            className="h-10 w-10 rounded-full object-cover"
                                                        />
                                                    ) : (
                                                        <span className="inline-flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 font-semibold text-primary text-sm">
                                                            {initialsOf(m.name)}
                                                        </span>
                                                    )}
                                                </td>
                                                <td>
                                                    <div className="font-medium">{m.name}</div>
                                                    <div className="text-xs text-muted-foreground">{m.role || '-'}</div>
                                                </td>
                                                <td className="font-mono text-xs">{m.phone || '-'}</td>
                                                <td>
                                                    <span
                                                        className={`badge badge--soft ${m.is_active ? 'badge--success' : 'badge--neutral'}`}
                                                    >
                                                        {m.is_active ? 'Aktif' : 'Nonaktif'}
                                                    </span>
                                                </td>
                                                <td>
                                                    <div className="flex justify-end gap-1">
                                                        <Link
                                                            href={`/midwives/${m.id}/edit`}
                                                            className="button button--sm button--ghost button--primary"
                                                        >
                                                            <PencilIcon />
                                                            Edit
                                                        </Link>
                                                        <button
                                                            type="button"
                                                            onClick={() => remove(m.id)}
                                                            className="button button--sm button--ghost button--danger"
                                                        >
                                                            <TrashIcon />
                                                            Hapus
                                                        </button>
                                                    </div>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                        {midwives.links && (
                            <Pagination meta={midwives} />
                        )}
                    </div>
                </div>
            </section>

            <ConfirmDialog
                open={confirmTarget !== null}
                title="Hapus Bidan"
                message="Data bidan ini akan dihapus permanen. Lanjutkan?"
                confirmLabel={deleting ? 'Menghapus...' : 'Hapus'}
                loading={deleting}
                onConfirm={handleConfirmDelete}
                onCancel={() => setConfirmTarget(null)}
            />
        </AdminLayout>
    );
}
