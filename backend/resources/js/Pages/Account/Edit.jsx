import { useRef } from 'react';
import AdminLayout from '../../Layouts/AdminLayout';
import { useForm } from '@inertiajs/react';
import PageHeader from '../../components/PageHeader';
import useUnsavedGuard from '../../hooks/useUnsavedGuard.jsx';
import { GearIcon } from '../../components/icons';

export default function AccountEdit() {
    const { data, setData, put, processing, errors } = useForm({
        current_password: '',
        new_password: '',
        new_password_confirmation: '',
    });

    const initialRef = useRef(JSON.stringify(data));
    const dirty = JSON.stringify(data) !== initialRef.current;
    const { markIntent, guardEl } = useUnsavedGuard(dirty);

    const submit = (e) => {
        e.preventDefault();
        markIntent();
        put('/account');
    };

    return (
        <AdminLayout>
            <PageHeader
                title="Akun"
                description="Perbarui password untuk masuk ke panel admin."
            />

            <form onSubmit={submit}>
                <div className="card">
                    <div className="card__body flex flex-col gap-6">
                        <div className="field">
                            <label htmlFor="current_password" className="field__label">Password Saat Ini</label>
                            <input
                                id="current_password"
                                type="password"
                                className="input"
                                autoComplete="current-password"
                                value={data.current_password}
                                onChange={(e) => setData('current_password', e.target.value)}
                            />
                            {errors.current_password && (
                                <p className="field__error">{errors.current_password}</p>
                            )}
                        </div>

                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                            <div className="field">
                                <label htmlFor="new_password" className="field__label">Password Baru</label>
                                <input
                                    id="new_password"
                                    type="password"
                                    className="input"
                                    autoComplete="new-password"
                                    value={data.new_password}
                                    onChange={(e) => setData('new_password', e.target.value)}
                                />
                                {errors.new_password && <p className="field__error">{errors.new_password}</p>}
                            </div>
                            <div className="field">
                                <label htmlFor="new_password_confirmation" className="field__label">
                                    Ulangi Password Baru
                                </label>
                                <input
                                    id="new_password_confirmation"
                                    type="password"
                                    className="input"
                                    autoComplete="new-password"
                                    value={data.new_password_confirmation}
                                    onChange={(e) => setData('new_password_confirmation', e.target.value)}
                                />
                            </div>
                        </div>
                    </div>
                </div>

                <div className="sticky-bar">
                    <button type="submit" className="button button--primary" disabled={processing}>
                        <GearIcon />
                        Ubah Password
                    </button>
                </div>
            </form>

            {guardEl}
        </AdminLayout>
    );
}
