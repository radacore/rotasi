export default function PageHeader({ title, description, children }) {
    return (
        <header className="page__header">
            <div className="page__headline">
                <h1 className="page__title">{title}</h1>
                {description && <p className="page__description">{description}</p>}
            </div>
            {children && <div className="page__action">{children}</div>}
        </header>
    );
}
