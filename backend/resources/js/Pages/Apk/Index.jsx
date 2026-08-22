import { useState } from 'react';
import AdminLayout from '../../Layouts/AdminLayout';
import { router, useForm } from '@inertiajs/react';
import PageHeader from '../../components/PageHeader';
import Pagination from '../../components/Pagination';
import ConfirmDialog from '../../components/ConfirmDialog';
import { DownloadIcon, PlusIcon, TrashIcon } from '../../components/icons';
import { useToast } from '../../components/Toasts';
import axios from 'axios';

const randomToken = () =>
    [...Array(32)].map(() => Math.floor(Math.random() * 16).toString(16)).join('');

function parseVersionFromFilename(name) {
    const base = String(name || '').replace(/\.apk$/i, '');
    // rotasi-1.0.10, rotasi_v1.2.3, app-1.0.10(101), 1.0.10, v1.2.3
    const m = base.match(/(\d+)\.(\d+)\.(\d+)/);
    if (!m) return null;
    const versionName = `${m[1]}.${m[2]}.${m[3]}`;
    const versionCode = parseInt(`${m[1]}${String(m[2]).padStart(2, '0')}${String(m[3]).padStart(2, '0')}`, 10);
    // cari angka dalam kurung sebagai versionCode eksplisit
    const paren = base.match(/\((\d+)\)/);
    return {
        version_name: versionName,
        version_code: paren ? parseInt(paren[1], 10) : versionCode,
    };
}

export default function ApkIndex({ releases, errors }) {
    const toast = useToast();
    const maxCode = Math.max(0, ...releases.data.map((r) => r.version_code ?? 0));
    const { data, setData, setError, reset } = useForm({
        version_code: '',
        version_name: '',
        release_notes: '',
        apk: null,
    });

    const onFileChange = (file) => {
        setData((prev) => {
            const next = { ...prev, apk: file };
            if (file) {
                const parsed = parseVersionFromFilename(file.name);
                if (parsed) {
                    // isi otomatis hanya jika field kosong atau masih nilai auto sebelumnya
                    if (!String(prev.version_name).trim()) next.version_name = parsed.version_name;
                    else {
                        const prevParsed = parseVersionFromFilename(prev.apk?.name || '');
                        if (prevParsed && prevParsed.version_name === prev.version_name) {
                            next.version_name = parsed.version_name;
                        }
                    }
                    if (!String(prev.version_code).trim()) next.version_code = String(parsed.version_code);
                    else {
                        const prevParsed = parseVersionFromFilename(prev.apk?.name || '');
                        if (prevParsed && String(prevParsed.version_code) === String(prev.version_code)) {
                            next.version_code = String(parsed.version_code);
                        }
                    }
                    // fallback: kalau masih kosong, pakai max+1
                    if (!String(next.version_code).trim()) next.version_code = String(maxCode + 1);
                } else if (!String(prev.version_code).trim()) {
                    next.version_code = String(maxCode + 1);
                }
            }
            return next;
        });
    };

    const [confirmTarget, setConfirmTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);
    const [uploading, setUploading] = useState(false);
    const [progress, setProgress] = useState(0);

    const submit = async (e) => {
        e.preventDefault();

        if (!data.apk) {
            setError('apk', 'Pilih file APK terlebih dahulu.');
            return;
        }

        const fd = new FormData();
        fd.append('version_code', data.version_code);
        fd.append('version_name', data.version_name);
        fd.append('release_notes', data.release_notes || '');
        fd.append('apk', data.apk);
        fd.append('upload_token', randomToken());

        setUploading(true);
        setProgress(0);

        let done = false;

        const pollProgress = async (token) => {
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

        const token = fd.get('upload_token');
        const post = axios.post('/apk', fd, {
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
            await Promise.all([post, pollProgress(token)]);
            toast('Rilis APK berhasil diunggah dan diaktifkan.');
            reset();
            router.reload();
        } catch (err) {
            const resp = err.response?.data;
            if (resp?.errors) {
                for (const [key, messages] of Object.entries(resp.errors)) {
                    setError(key, Array.isArray(messages) ? messages[0] : messages);
                }
            } else {
                toast(resp?.message || 'Gagal mengunggah rilis.', 'danger');
            }
        } finally {
            done = true;
            setUploading(false);
        }
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
                            <div className="field">
                                <label htmlFor="apk" className="field__label">
                                    File APK <span className="text-danger">*</span>
                                </label>
                                <input
                                    id="apk"
                                    type="file"
                                    accept=".apk,application/vnd.android.package-archive"
                                    className="input"
                                    disabled={uploading}
                                    onChange={(e) => onFileChange(e.target.files[0] ?? null)}
                                />
                                <p className="text-xs text-muted-foreground mt-1">
                                    Pilih file seperti <code>rotasi-1.0.10.apk</code> — kode &amp; nama versi akan terisi otomatis. Otomatis jadi versi aktif.
                                </p>
                                {errors.apk && <p className="field__error">{errors.apk}</p>}
                            </div>

                            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                                <div className="field">
                                    <label htmlFor="version_code" className="field__label">
                                        Kode Versi <span className="text-muted-foreground font-normal">(otomatis)</span>
                                    </label>
                                    <input
                                        id="version_code"
                                        type="number"
                                        min="1"
                                        className="input"
                                        value={data.version_code}
                                        disabled={uploading}
                                        placeholder={String(maxCode + 1)}
                                        onChange={(e) => setData('version_code', e.target.value)}
                                    />
                                    {errors.version_code && <p className="field__error">{errors.version_code}</p>}
                                </div>
                                <div className="field">
                                    <label htmlFor="version_name" className="field__label">
                                        Nama Versi <span className="text-muted-foreground font-normal">(otomatis)</span>
                                    </label>
                                    <input
                                        id="version_name"
                                        className="input"
                                        value={data.version_name}
                                        disabled={uploading}
                                        placeholder="mis. 1.0.10"
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
                                    placeholder="Opsional"
                                    value={data.release_notes}
                                    disabled={uploading}
                                    onChange={(e) => setData('release_notes', e.target.value)}
                                />
                            </div>
                        </div>
                        <div className="card__footer flex flex-col gap-3">
                            {uploading && (
                                <div>
                                    <div className="flex items-center justify-between text-sm mb-1">
                                        <span className="text-muted-foreground truncate">
                                            Mengunggah {data.apk?.name || 'APK'}…
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
                                        Unggah Rilis
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
                                            <th>QR Code</th>
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
                                                <td>
                                                    <div className="flex items-center gap-3">
                                                        <img
                                                            src={`/apk/${r.id}/qr`}
                                                            alt={`QR versi ${r.version_name}`}
                                                            width={44}
                                                            height={44}
                                                            className="shrink-0 border rounded-sm"
                                                        />
                                                        <a
                                                            href={`/apk/${r.id}/qr/download`}
                                                            download
                                                            className="link text-xs"
                                                        >
                                                            <DownloadIcon />
                                                            Unduh QR HD
                                                        </a>
                                                    </div>
                                                    <p className="text-muted-foreground text-xs mt-1">
                                                        Scan untuk langsung mengunduh APK.
                                                    </p>
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
