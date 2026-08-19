const HEADER_KEYS = ['s0', 's1', 's2', 's3', 's4'];
const ROW_KEYS = ['r0', 'r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7'];

export default function PageSkeleton({ columns = 5, rows = 6 }) {
    const header = HEADER_KEYS.slice(0, columns);
    const body = ROW_KEYS.slice(0, rows);

    return (
        <div className="page">
            <div className="flex items-center justify-between gap-4">
                <div className="flex flex-col gap-2">
                    <span className="placeholder placeholder--wave block" style={{ width: '16rem', height: '1.5rem' }} />
                    <span className="placeholder placeholder--wave block" style={{ width: '22rem', height: '0.875rem' }} />
                </div>
                <span className="placeholder placeholder--wave block" style={{ width: '8rem', height: '2.5rem' }} />
            </div>

            <div className="card">
                <div className="card__body">
                    <div className="table-responsive">
                        <table className="table">
                            <thead>
                                <tr>
                                    {header.map((k, i) => (
                                        <th key={k}>
                                            <span
                                                className="placeholder placeholder--wave block"
                                                style={{ width: `${55 + (i % 3) * 20}%` }}
                                            />
                                        </th>
                                    ))}
                                </tr>
                            </thead>
                            <tbody>
                                {body.map((k) => (
                                    <tr key={k}>
                                        {header.map((h, i) => (
                                            <td key={`${k}-${h}`}>
                                                <span
                                                    className="placeholder placeholder--wave block"
                                                    style={{ width: `${60 + ((k.length + i) % 3) * 15}%` }}
                                                />
                                            </td>
                                        ))}
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    );
}
