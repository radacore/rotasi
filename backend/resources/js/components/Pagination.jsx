import { Link } from '@inertiajs/react';

const ENTITIES = {
    '&laquo;': '«',
    '&raquo;': '»',
    '&hellip;': '…',
    '&nbsp;': ' ',
};

function plainLabel(label) {
    return label.replace(/&(laquo|raquo|hellip|nbsp);/g, (m) => ENTITIES[m]);
}

export default function Pagination({ meta }) {
    if (!meta || meta.last_page <= 1) return null;

    const { links, current_page, from, to, total } = meta;

    return (
        <div className="flex flex-wrap items-center justify-between gap-4">
            <p className="text-sm text-muted-foreground">
                Menampilkan {from ?? 0}–{to ?? 0} dari {total} data
            </p>
            <nav className="pagination" aria-label="Navigasi halaman">
                {links.map((link, i) => {
                    const key = link.url ? link.url : `${link.label}-${i}`;
                    const label = <span>{plainLabel(link.label)}</span>;
                    if (!link.url) {
                        return (
                            <span key={key} className="pagination__button" aria-disabled="true">
                                {label}
                            </span>
                        );
                    }
                    if (link.active) {
                        return (
                            <span key={key} className="pagination__button" aria-current="page">
                                {label}
                            </span>
                        );
                    }
                    return (
                        <Link key={key} href={link.url} className="pagination__button" preserveScroll>
                            {label}
                        </Link>
                    );
                })}
            </nav>
            <p className="text-sm text-muted-foreground">
                Halaman {current_page} dari {meta.last_page}
            </p>
        </div>
    );
}
