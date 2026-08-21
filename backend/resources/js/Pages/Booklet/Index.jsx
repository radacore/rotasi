import { useState } from 'react';
import AdminLayout from '../../Layouts/AdminLayout';
import { router, useForm } from '@inertiajs/react';
import PageHeader from '../../components/PageHeader';
import Pagination from '../../components/Pagination';
import ConfirmDialog from '../../components/ConfirmDialog';
import { useToast } from '../../components/Toasts';
import { DownloadIcon, PlusIcon, TrashIcon } from '../../components/icons';
import axios from 'axios';

const formatBytes = (bytes) => {
    if (!bytes) return '-';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
};

export default function BookletIndex({ releases, errors }) {
    const toast = useToast();
    const { data, setData, errors: formErrors, setError, reset } = useForm({
        title: '',
        file: null,
        is_active: true,
    });

    const [confirmTarget, setConfirmTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);
    const [uploading, setUploading] = useState(false);
    const [progress, setProgress] = useState(0);

    const randomToken = () =>
        [...Array(32)].map(() => Math.floor(Math.random() * 16).toString(16)).join('');

    const submit = async (e) => {
        e.preventDefault();

        if (!data.file) {
            setError('file', 'Pilih file PDF terlebih dahulu.');
            return;
        }

        const token = randomToken();

        const fd = new FormData();
        fd.append('title', data.title);
        fd.append('file', data.file);
        fd.append('is_active', data.is_active ? '1' : '');
        fd.append('upload_token', token);

        setUploading(true);
        setProgress(0);

        let done = false;

        const pollProgress = async () => {
            while (!done) {
                await new Promise((r) => setTimeout(r, 600));
                try {
                    const res = await axios.get(`/uploads/progress/${token}`, {
                        headers: { Accept: 'application/json' },
                    });
                    const s3 = res.data;
                    if (s3.total > 0) {
                        setProgress(Math.min(100, Math.round(50 + (s3.percent / 100) * 50)));
                    }
                } catch {
                    // abaikan, lanjut polling
                }
            }
        };

        const post = axios.post('/booklet', fd, {
            headers: { Accept: 'application/json' },
            onUploadProgress: (evt) => {
                if (evt.total) {
                    setProgress(Math.min(50, Math.round((evt.loaded / evt.total) * 50)));
                }
            },
        });
        post.finally(() => {
            done = true;
        });

        try {
            await Promise.all([
                post,
                pollProgress(),
            ]);
            toast('Booklet berhasil diunggah.');
            reset();
            router.reload();
        } catch (err) {
            const resp = err.response?.data;
            if (resp?.errors) {
                for (const [key, messages] of Object.entries(resp.errors)) {
                    setError(key, Array.isArray(messages) ? messages[0] : messages);
                }
            } else {
                toast(resp?.message || 'Gagal mengunggah booklet.', 'danger');
            }
        } finally {
            done = true;
            setUploading(false);
        }
    };

    const activate = (id) => router.post(`/booklet/${id}/activate`);
    const deactivate = (id) => router.post(`/booklet/${id}/deactivate`);

    const remove = (id) => setConfirmTarget({ id });

    const handleConfirmDelete = () => {
        setDeleting(true);
        router.delete(`/booklet/${confirmTarget.id}`, {
            onFinish: () => {
                setDeleting(false);
                setConfirmTarget(null);
            },
        });
    };

    return (
        <AdminLayout>
            <PageHeader
                title="Booklet"
                description="Kelola booklet PDF yang ditampilkan di aplikasi pasien."
            />

            {formErrors?.delete && (
                <div className="alert alert--danger">
                    <p>{formErrors.delete}</p>
                </div>
            )}

            <section className="page__section">
                <div className="card">
                    <div className="card__header">
                        <div className="card__heading">
                            <h2 className="card__title">Unggah Booklet Baru</h2>
                        </div>
                    </div>
                    <form onSubmit={submit}>
                        <div className="card__body flex flex-col gap-6">
                            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                                <div className="field">
                                    <label htmlFor="title" className="field__label">Judul Booklet</label>
                                    <input
                                        id="title"
                                        className="input"
                                        value={data.title}
                                        disabled={uploading}
                                        onChange={(e) => setData('title', e.target.value)}
                                    />
                                    {formErrors.title && <p className="field__error">{formErrors.title}</p>}
                                </div>

                                <div className="field">
                                    <label htmlFor="file" className="field__label">File PDF</label>
                                    <input
                                        id="file"
                                        type="file"
                                        accept=".pdf,application/pdf"
                                        className="input"
                                        disabled={uploading}
                                        onChange={(e) => setData('file', e.target.files[0])}
                                    />
                                    {formErrors.file && <p className="field__error">{formErrors.file}</p>}
                                </div>
                            </div>

                            <div className="field flex items-center gap-3">
                                <label className="flex items-center gap-2 cursor-pointer" htmlFor="is_active">
                                    <input
                                        id="is_active"
                                        type="checkbox"
                                        className="checkbox"
                                        checked={data.is_active}
                                        disabled={uploading}
                                        onChange={(e) => setData('is_active', e.target.checked)}
                                    />
                                    Jadikan versi aktif
                                </label>
                            </div>
                        </div>
                        <div className="card__footer flex flex-col gap-3">
                            {uploading && (
                                <div>
                                    <div className="flex items-center justify-between text-sm mb-1">
                                        <span className="text-muted-foreground truncate">
                                            Mengunggah {data.file?.name}…
                                        </span>
                                        <span className="font-medium">{progress}%</span>
                                    </div>
                                    <div className="w-full h-2 rounded-full bg-background overflow-hidden">
                                        <div
                                            className="h-full rounded-full transition-all duration-150"
                                            style={{ width: `${progress}%`, backgroundColor: '#2563eb' }}
                                        />
                                    </div>
                                </div>
                            )}
                            <button type="submit" className="button button--primary" disabled={uploading}>
                                {uploading ? (
                                    <>Mengunggah… {progress}%</>
                                ) : (
                                    <>
                                        <PlusIcon />
                                        Unggah Booklet
                                    </>
                                )}
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
                                <p className="empty-state__title">Belum ada booklet</p>
                                <p className="empty-state__description">
                                    Unggah booklet versi pertama untuk dibaca di aplikasi.
                                </p>
                            </div>
                        ) : (
                            <div className="table-responsive">
                                <table className="table table--hover">
                                    <thead>
                                        <tr>
                                            <th>Booklet</th>
                                            <th>Ukuran</th>
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
                                                        {r.title}
                                                        <span className="text-muted-foreground"> (v{r.version})</span>
                                                    </div>
                                                    <a
                                                        href={r.file_url}
                                                        target="_blank"
                                                        rel="noreferrer"
                                                        className="link text-xs"
                                                    >
                                                        <DownloadIcon />
                                                        Unduh
                                                    </a>
                                                </td>
                                                <td className="text-muted-foreground">{formatBytes(r.file_size)}</td>
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
                                                        {r.is_active ? (
                                                            <button
                                                                type="button"
                                                                onClick={() => deactivate(r.id)}
                                                                className="button button--sm button--ghost button--neutral"
                                                            >
                                                                Nonaktifkan
                                                            </button>
                                                        ) : (
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
                title="Hapus Booklet"
                message="Booklet ini akan dihapus permanen. Lanjutkan?"
                confirmLabel={deleting ? 'Menghapus...' : 'Hapus'}
                loading={deleting}
                onConfirm={handleConfirmDelete}
                onCancel={() => setConfirmTarget(null)}
            />
        </AdminLayout>
    );
}
