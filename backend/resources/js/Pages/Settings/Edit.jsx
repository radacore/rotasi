import { useRef } from 'react';
import AdminLayout from '../../Layouts/AdminLayout';
import { useForm } from '@inertiajs/react';
import PageHeader from '../../components/PageHeader';
import useUnsavedGuard from '../../hooks/useUnsavedGuard.jsx';
import { GearIcon } from '../../components/icons';

export default function SettingsEdit({ settings }) {
    const colorOptions = ['green', 'yellow', 'orange', 'red'];
    const { data, setData, put, processing, errors } = useForm({
        emergency_phone: settings.emergency_phone,
        puskesmas_name: settings.puskesmas_name,
        puskesmas_address: settings.puskesmas_address,
        default_wa_message: settings.default_wa_message,
        kick_threshold: settings.kick_threshold,
        referral_persistent_colors: settings.referral_persistent_colors ?? ['orange', 'red'],
        referral_symptom_check_trigger: settings.referral_symptom_check_trigger ?? true,
    });

    const initialRef = useRef(JSON.stringify(data));
    const dirty = JSON.stringify(data) !== initialRef.current;
    const { markIntent, guardEl } = useUnsavedGuard(dirty);

    const submit = (e) => {
        e.preventDefault();
        markIntent();
        put('/settings');
    };

    return (
        <AdminLayout>
            <PageHeader
                title="Pengaturan"
                description="Konfigurasi umum yang dipakai aplikasi dan alur darurat."
            />

            <form onSubmit={submit}>
                <div className="card">
                    <div className="card__body flex flex-col gap-6">
                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                            <div className="field">
                                <label htmlFor="emergency_phone" className="field__label">Telepon Darurat</label>
                                <input
                                    id="emergency_phone"
                                    className="input"
                                    placeholder="+62 8xx..."
                                    value={data.emergency_phone}
                                    onChange={(e) => setData('emergency_phone', e.target.value)}
                                />
                                {errors.emergency_phone && <p className="field__error">{errors.emergency_phone}</p>}
                            </div>
                            <div className="field">
                                <label htmlFor="puskesmas_name" className="field__label">Nama Puskesmas</label>
                                <input
                                    id="puskesmas_name"
                                    className="input"
                                    value={data.puskesmas_name}
                                    onChange={(e) => setData('puskesmas_name', e.target.value)}
                                />
                            </div>
                        </div>

                        <div className="field">
                            <label htmlFor="puskesmas_address" className="field__label">Alamat Puskesmas</label>
                            <input
                                id="puskesmas_address"
                                className="input"
                                value={data.puskesmas_address}
                                onChange={(e) => setData('puskesmas_address', e.target.value)}
                            />
                        </div>

                        <div className="field">
                            <label htmlFor="default_wa_message" className="field__label">
                                Pesan WhatsApp Default
                            </label>
                            <textarea
                                id="default_wa_message"
                                rows={5}
                                className="textarea"
                                value={data.default_wa_message}
                                onChange={(e) => setData('default_wa_message', e.target.value)}
                            />
                        </div>

                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                            <div className="field">
                                <label htmlFor="kick_threshold" className="field__label">
                                    Ambang Gerakan Janin
                                </label>
                                <input
                                    id="kick_threshold"
                                    type="number"
                                    min="1"
                                    className="input"
                                    value={data.kick_threshold}
                                    onChange={(e) => setData('kick_threshold', e.target.value)}
                                />
                                {errors.kick_threshold && <p className="field__error">{errors.kick_threshold}</p>}
                            </div>
                            <div className="field">
                                <span className="field__label">Warna rujukan persisten</span>
                                <div className="flex flex-wrap gap-3">
                                    {colorOptions.map((c) => (
                                        <label key={c} className="inline-flex items-center gap-2 text-sm">
                                            <input
                                                type="checkbox"
                                                checked={data.referral_persistent_colors.includes(c)}
                                                onChange={(e) => {
                                                    const next = e.target.checked
                                                        ? [...data.referral_persistent_colors, c]
                                                        : data.referral_persistent_colors.filter((x) => x !== c);
                                                    setData('referral_persistent_colors', next);
                                                }}
                                            />
                                            <span className="capitalize">{c}</span>
                                        </label>
                                    ))}
                                </div>
                                {errors.referral_persistent_colors && <p className="field__error">{errors.referral_persistent_colors}</p>}
                            </div>
                        </div>
                        <label className="inline-flex items-center gap-2 text-sm font-medium">
                            <input
                                type="checkbox"
                                checked={!!data.referral_symptom_check_trigger}
                                onChange={(e) => setData('referral_symptom_check_trigger', e.target.checked)}
                            />
                            Picu rujukan bila cek gejala ada tanda bahaya
                        </label>
                    </div>
                </div>

                <div className="sticky-bar">
                    <button type="submit" className="button button--primary" disabled={processing}>
                        <GearIcon />
                        Simpan Pengaturan
                    </button>
                </div>
            </form>

            {guardEl}
        </AdminLayout>
    );
}
