import { useState } from 'react';
import AdminLayout from '../../Layouts/AdminLayout';
import { router } from '@inertiajs/react';
import PageHeader from '../../components/PageHeader';
import Pagination from '../../components/Pagination';
import ConfirmDialog from '../../components/ConfirmDialog';
import { useToast } from '../../components/Toasts';
import axios from 'axios';
import { ImageIcon, PlusIcon, TrashIcon } from '../../components/icons';

function formatSize(bytes) {
    if (!bytes) return '-';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export default function MediaIndex({ media }) {
    const toast = useToast();
    const [confirmTarget, setConfirmTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);
    const [uploading, setUploading] = useState(false);

    const upload = async (e) => {
        const file = e.target.files[0];
        if (!file) return;

        const fd = new FormData();
        fd.append('file', file);

        setUploading(true);
        try {
            await axios.post('/media', fd, {
                headers: { Accept: 'application/json' },
            });
            toast('Gambar berhasil diunggah.');
            router.reload();
        } catch {
            toast('Gagal mengunggah gambar.', 'danger');
        } finally {
            setUploading(false);
        }
        e.target.value = '';
    };

    const remove = (id) => setConfirmTarget({ id });

    const handleConfirmDelete = () => {
        setDeleting(true);
        router.delete(`/media/${confirmTarget.id}`, { onFinish: () => setDeleting(false) });
    };

    return (
        <AdminLayout>
            <PageHeader
                title="Media"
                description="Koleksi gambar untuk ilustrasi konten edukasi."
            >
                <label className="button button--primary cursor-pointer">
                    <PlusIcon />
                    Unggah Gambar
                    <input type="file" accept="image/*" className="hidden" onChange={upload} />
                </label>
            </PageHeader>

            <section className="page__section">
                {media.data.length === 0 && !uploading ? (
                    <div className="card">
                        <div className="card__body">
                            <div className="empty-state">
                                <ImageIcon />
                                <p className="empty-state__title">Belum ada media</p>
                                <p className="empty-state__description">
                                    Unggah gambar untuk dipakai sebagai ilustrasi konten.
                                </p>
                            </div>
                        </div>
                    </div>
                ) : (
                    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
                        {media.data.map((m) => (
                            <div key={m.id} className="card overflow-hidden">
                                <div className="relative">
                                    <img
                                        src={m.url}
                                        alt={m.original_filename}
                                        className="w-full h-28 object-cover"
                                    />
                                    <button
                                        type="button"
                                        onClick={() => remove(m.id)}
                                        className="button button--icon-only button--sm button--neutral absolute top-2 right-2 bg-background/80 backdrop-blur"
                                        aria-label="Hapus media"
                                    >
                                        <TrashIcon />
                                    </button>
                                </div>
                                <div className="p-3">
                                    <p className="text-sm font-medium truncate" title={m.original_filename}>
                                        {m.original_filename}
                                    </p>
                                    <p className="text-xs text-muted-foreground">{formatSize(m.file_size)}</p>
                                </div>
                            </div>
                        ))}
                        {uploading && (
                            <div className="card overflow-hidden">
                                <span className="placeholder placeholder--wave block w-full h-28" />
                                <div className="p-3 flex flex-col gap-2">
                                    <span className="placeholder placeholder--wave block w-3/4" />
                                    <span className="placeholder placeholder--wave block w-1/3" />
                                </div>
                            </div>
                        )}
                    </div>
                )}
                {media.links && (
                    <Pagination meta={media} />
                )}
            </section>

            <ConfirmDialog
                open={confirmTarget !== null}
                title="Hapus Media"
                message="Gambar akan dihapus permanen dari penyimpanan. Lanjutkan?"
                confirmLabel={deleting ? 'Menghapus...' : 'Hapus'}
                loading={deleting}
                onConfirm={handleConfirmDelete}
                onCancel={() => setConfirmTarget(null)}
            />
        </AdminLayout>
    );
}
