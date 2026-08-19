import { useRef, useState } from 'react';
import AdminLayout from '../../Layouts/AdminLayout';
import { Link, useForm } from '@inertiajs/react';
import PageHeader from '../../components/PageHeader';
import useUnsavedGuard from '../../hooks/useUnsavedGuard.jsx';
import { ArrowLeftIcon, TrashIcon } from '../../components/icons';

const ROLES = ['Bidan', 'Bidan Pelaksana', 'Bidan Koordinator'];
const WORKDAYS = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

export default function MidwivesForm({ midwife }) {
    const isEdit = !!midwife;
    const [dutyStart, dutyEnd] = (midwife?.duty_hours ?? '').split('-');

    const { data, setData, post, put, processing, errors } = useForm({
        name: midwife?.name ?? '',
        role: midwife?.role ?? 'Bidan',
        phone: midwife?.phone ?? '',
        alt_phone: midwife?.alt_phone ?? '',
        duty_hours_start: dutyStart || '',
        duty_hours_end: dutyEnd || '',
        workdays: midwife?.workdays ?? [],
        photo: null,
        remove_photo: false,
        is_active: midwife?.is_active ?? true,
        notes: midwife?.notes ?? '',
    });

    const [photoPreview, setPhotoPreview] = useState(null);
    const fileInputRef = useRef(null);

    const initialRef = useRef(JSON.stringify(data));
    const dirty = JSON.stringify(data) !== initialRef.current;
    const { markIntent, guardEl } = useUnsavedGuard(dirty);

    const onPhotoChange = (e) => {
        const file = e.target.files?.[0] || null;
        setData('photo', file);
        setData('remove_photo', false);
        setPhotoPreview(file ? URL.createObjectURL(file) : null);
    };

    const removePhoto = () => {
        setData('photo', null);
        setData('remove_photo', true);
        setPhotoPreview(null);
        if (fileInputRef.current) fileInputRef.current.value = '';
    };

    const toggleWorkday = (day) => {
        const next = data.workdays.includes(day)
            ? data.workdays.filter((d) => d !== day)
            : [...data.workdays, day];
        setData('workdays', next);
    };

    const submit = (e) => {
        e.preventDefault();
        markIntent();
        if (isEdit) {
            put(`/midwives/${midwife.id}`);
        } else {
            post('/midwives');
        }
    };

    return (
        <AdminLayout>
            <PageHeader
                title={isEdit ? 'Edit Bidan' : 'Bidan Baru'}
                description="Data petugas yang bertugas melaporkan kondisi kehamilan pasien."
            >
                <Link href="/midwives" className="button button--ghost button--neutral">
                    <ArrowLeftIcon />
                    Kembali
                </Link>
            </PageHeader>

            <form onSubmit={submit}>
                <div className="card">
                    <div className="card__body flex flex-col gap-6">
                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                            <div className="field">
                                <label htmlFor="name" className="field__label">Nama Lengkap</label>
                                <input
                                    id="name"
                                    className="input"
                                    value={data.name}
                                    onChange={(e) => setData('name', e.target.value)}
                                />
                                {errors.name && <p className="field__error">{errors.name}</p>}
                            </div>
                            <div className="field">
                                <label htmlFor="role" className="field__label">Peran</label>
                                <select
                                    id="role"
                                    className="select"
                                    value={data.role}
                                    onChange={(e) => setData('role', e.target.value)}
                                >
                                    {ROLES.map((role) => (
                                        <option key={role} value={role}>{role}</option>
                                    ))}
                                </select>
                                {errors.role && <p className="field__error">{errors.role}</p>}
                            </div>
                            <div className="field">
                                <label htmlFor="phone" className="field__label">Telepon atau Nomor Whatsapp</label>
                                <input
                                    id="phone"
                                    className="input"
                                    value={data.phone}
                                    onChange={(e) => setData('phone', e.target.value)}
                                />
                                {errors.phone && <p className="field__error">{errors.phone}</p>}
                            </div>
                            <div className="field">
                                <label htmlFor="alt_phone" className="field__label">Telepon Alternatif</label>
                                <input
                                    id="alt_phone"
                                    className="input"
                                    value={data.alt_phone}
                                    onChange={(e) => setData('alt_phone', e.target.value)}
                                />
                            </div>
                            <div className="field">
                                <label htmlFor="duty_hours_start" className="field__label">Jam Jaga</label>
                                <div className="grid grid-cols-2 gap-3">
                                    <input
                                        type="time"
                                        className="input"
                                        value={data.duty_hours_start}
                                        onChange={(e) => setData('duty_hours_start', e.target.value)}
                                    />
                                    <input
                                        type="time"
                                        className="input"
                                        value={data.duty_hours_end}
                                        onChange={(e) => setData('duty_hours_end', e.target.value)}
                                    />
                                </div>
                                <p className="field__hint">
                                    Jam mulai dan selesai (format 24 jam). Kosongkan bila tidak berjaga.
                                </p>
                                {errors.duty_hours_start && <p className="field__error">{errors.duty_hours_start}</p>}
                                {errors.duty_hours_end && <p className="field__error">{errors.duty_hours_end}</p>}
                            </div>
                            <div className="field">
                                <span className="field__label">Hari Kerja</span>
                                <div className="flex flex-wrap gap-4">
                                    {WORKDAYS.map((day) => (
                                        <label
                                            key={day}
                                            className="flex items-center gap-2 cursor-pointer"
                                            htmlFor={`workday-${day}`}
                                        >
                                            <input
                                                id={`workday-${day}`}
                                                type="checkbox"
                                                className="checkbox"
                                                checked={data.workdays.includes(day)}
                                                onChange={() => toggleWorkday(day)}
                                            />
                                            {day}
                                        </label>
                                    ))}
                                </div>
                                {errors.workdays && <p className="field__error">{errors.workdays}</p>}
                            </div>
                            <div className="field">
                                <label htmlFor="photo" className="field__label">Foto (opsional)</label>
                                <div className="flex items-center gap-4">
                                    {photoPreview || (isEdit && midwife.photo_url && !data.remove_photo) ? (
                                        <img
                                            src={photoPreview || midwife.photo_url}
                                            alt="Foto bidan"
                                            className="h-16 w-16 rounded-full object-cover"
                                        />
                                    ) : null}
                                    <div className="flex flex-col gap-2">
                                        <input
                                            ref={fileInputRef}
                                            id="photo"
                                            type="file"
                                            accept="image/*"
                                            className="input"
                                            onChange={onPhotoChange}
                                        />
                                        {isEdit && midwife.photo_url && !data.remove_photo && (
                                            <button
                                                type="button"
                                                className="button button--sm button--ghost button--danger self-start"
                                                onClick={removePhoto}
                                            >
                                                <TrashIcon />
                                                Hapus Foto
                                            </button>
                                        )}
                                    </div>
                                </div>
                                {errors.photo && <p className="field__error">{errors.photo}</p>}
                            </div>
                            {isEdit && (
                                <div className="field flex items-end gap-3 pb-2">
                                    <label className="flex items-center gap-2 cursor-pointer" htmlFor="is_active">
                                        <input
                                            id="is_active"
                                            type="checkbox"
                                            className="checkbox"
                                            checked={!data.is_active}
                                            onChange={(e) => setData('is_active', !e.target.checked)}
                                        />
                                        Nonaktifkan
                                    </label>
                                </div>
                            )}
                        </div>

                        <div className="field">
                            <label htmlFor="notes" className="field__label">Catatan</label>
                            <textarea
                                id="notes"
                                rows={4}
                                className="textarea"
                                value={data.notes}
                                onChange={(e) => setData('notes', e.target.value)}
                            />
                        </div>
                    </div>
                </div>

                <div className="sticky-bar">
                    <button type="submit" className="button button--primary" disabled={processing}>
                        {isEdit ? 'Simpan Perubahan' : 'Buat Bidan'}
                    </button>
                    <Link href="/midwives" className="button button--ghost button--neutral">
                        Batal
                    </Link>
                </div>
            </form>

            {guardEl}
        </AdminLayout>
    );
}
