import { useState } from 'react';
import AdminLayout from '../../Layouts/AdminLayout';
import { router, useForm } from '@inertiajs/react';
import PageHeader from '../../components/PageHeader';
import Pagination from '../../components/Pagination';
import ConfirmDialog from '../../components/ConfirmDialog';
import { DownloadIcon, PlusIcon, TrashIcon } from '../../components/icons';

export default function ApkIndex({ releases, errors }) {
    const { data, setData, post, processing } = useForm({
        version_code: '',
        version_name: '',
        release_notes: '',
        download_url: '',
        is_active: true,
    });

    const [confirmTarget, setConfirmTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);

    const submit = (e) => {
        e.preventDefault();
        post('/apk');
    };

    const activate = (id) => router.post(`/apk/${id}/activate`);

    const remove = (id) => setConfirmTarget({ id });

    const handleConfirmDelete = () => {
        setDeleting(true);
        router.delete(`/apk/${confirmTarget.id}`, {
            onFinish: () => {
                setDeleting(false);
                setConfirmTarget(null);
            },
        });
    };

    return (
        <AdminLayout>
            <PageHeader
                title="Rilis APK"
                description="Kelola versi aplikasi Android untuk perangkat bidan."
            />

            {errors?.delete && (
                <div className="alert alert--danger">
                    <p>{errors.delete}</p>
                </div>
            )}

            <section className="page__section">
                <div className="card">
                    <div className="card__header">
                        <div className="card__heading">
                            <h2 className="card__title">Unggah Rilis Baru</h2>
                        </div>
                    </div>
                    <form onSubmit={submit}>
                        <div className="card__body flex flex-col gap-6">
                            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                                <div className="field">
                                    <label htmlFor="version_code" className="field__label">Kode Versi</label>
                                    <input
                                        id="version_code"
                                        type="number"
                                        min="1"
                                        className="input"
                                        value={data.version_code}
                                        onChange={(e) => setData('version_code', e.target.value)}
                                    />
                                    {errors.version_code && <p className="field__error">{errors.version_code}</p>}
                                </div>
                                <div className="field">
                                    <label htmlFor="version_name" className="field__label">Nama Versi</label>
                                    <input
                                        id="version_name"
                                        className="input"
                                        value={data.version_name}
                                        onChange={(e) => setData('version_name', e.target.value)}
                                    />
                                    {errors.version_name && <p className="field__error">{errors.version_name}</p>}
                                </div>
                            </div>

                            <div className="field">
                                <label htmlFor="release_notes" className="field__label">Catatan Rilis</label>
                                <textarea
                                    id="release_notes"
                                    rows={3}
                                    className="textarea"
                                    value={data.release_notes}
                                    onChange={(e) => setData('release_notes', e.target.value)}
                                />
                            </div>

                            <div className="field">
                                <label htmlFor="apk" className="field__label">File APK</label>
                                <input
                                    id="apk"
                                    type="file"
                                    accept=".apk,application/vnd.android.package-archive"
                                    className="input"
                                    onChange={(e) => setData('apk', e.target.files[0])}
                                />
                                {errors.apk && <p className="field__error">{errors.apk}</p>}
                            </div>

                            <div className="field">
                                <label htmlFor="download_url" className="field__label">Atau URL Unduhan</label>
                                <input
                                    id="download_url"
                                    className="input"
                                    placeholder="https://..."
                                    value={data.download_url}
                                    onChange={(e) => setData('download_url', e.target.value)}
                                />
                                {errors.download_url && <p className="field__error">{errors.download_url}</p>}
                            </div>

                            <div className="field flex items-center gap-3">
                                <label className="flex items-center gap-2 cursor-pointer" htmlFor="is_active">
                                    <input
                                        id="is_active"
                                        type="checkbox"
                                        className="checkbox"
                                        checked={data.is_active}
                                        onChange={(e) => setData('is_active', e.target.checked)}
                                    />
                                    Jadikan versi aktif
                                </label>
                            </div>
                        </div>
                        <div className="card__footer">
                            <button type="submit" className="button button--primary" disabled={processing}>
                                <PlusIcon />
                                Unggah Rilis
                            </button>
                        </div>
                    </form>
                </div>
            </section>

            <section className="page__section">
                <div className="card">
                    <div className="card__body">
                        {releases.data.length === 0 ? (
                            <div className="empty-state">
                                <DownloadIcon />
                                <p className="empty-state__title">Belum ada rilis</p>
                                <p className="empty-state__description">
                                    Unggah versi pertama aplikasi untuk perangkat bidan.
                                </p>
                            </div>
                        ) : (
                            <div className="table-responsive">
                                <table className="table table--hover">
                                    <thead>
                                        <tr>
                                            <th>Versi</th>
                                            <th>Catatan</th>
                                            <th>Tanggal</th>
                                            <th>Status</th>
                                            <th className="text-right">Aksi</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {releases.data.map((r) => (
                                            <tr key={r.id}>
                                                <td>
                                                    <div className="font-medium">
                                                        {r.version_name}
                                                        <span className="text-muted-foreground"> ({r.version_code})</span>
                                                    </div>
                                                    <a
                                                        href={r.download_url}
                                                        target="_blank"
                                                        rel="noreferrer"
                                                        className="link text-xs"
                                                    >
                                                        <DownloadIcon />
                                                        Unduh
                                                    </a>
                                                </td>
                                                <td className="max-w-xs">
                                                    <p className="whitespace-pre-line text-sm">{r.release_notes || '-'}</p>
                                                </td>
                                                <td className="text-muted-foreground">{r.uploaded_at}</td>
                                                <td>
                                                    <span
                                                        className={`badge badge--soft ${r.is_active ? 'badge--success' : 'badge--neutral'}`}
                                                    >
                                                        {r.is_active ? 'Aktif' : 'Arsip'}
                                                    </span>
                                                </td>
                                                <td>
                                                    <div className="flex justify-end gap-1">
                                                        {!r.is_active && (
                                                            <button
                                                                type="button"
                                                                onClick={() => activate(r.id)}
                                                                className="button button--sm button--ghost button--primary"
                                                            >
                                                                Aktifkan
                                                            </button>
                                                        )}
                                                        <button
                                                            type="button"
                                                            onClick={() => remove(r.id)}
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
                        {releases.links && (
                            <Pagination meta={releases} />
                        )}
                    </div>
                </div>
            </section>

            <ConfirmDialog
                open={confirmTarget !== null}
                title="Hapus Rilis"
                message="Rilis APK ini akan dihapus permanen. Lanjutkan?"
                confirmLabel={deleting ? 'Menghapus...' : 'Hapus'}
                loading={deleting}
                onConfirm={handleConfirmDelete}
                onCancel={() => setConfirmTarget(null)}
            />
        </AdminLayout>
    );
}
