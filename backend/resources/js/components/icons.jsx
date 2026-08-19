const base = {
    width: '1em',
    height: '1em',
    viewBox: '0 0 24 24',
    fill: 'currentColor',
};

export function LogoIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path d="M12 1.5l3.4 7.1 7.1 3.4-7.1 3.4-3.4 7.1-3.4-7.1L1.5 12l7.1-3.4z" opacity=".45" />
            <path d="M12 1.5l3.4 7.1L12 12 8.6 8.6z" />
        </svg>
    );
}

export function DashboardIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                d="M2 6.5c0-2.121 0-3.182.659-3.841S4.379 2 6.5 2s3.182 0 3.841.659S11 4.379 11 6.5s0 3.182-.659 3.841S8.621 11 6.5 11s-3.182 0-3.841-.659S2 8.621 2 6.5m11 11c0-2.121 0-3.182.659-3.841S15.379 13 17.5 13s3.182 0 3.841.659S22 15.379 22 17.5s0 3.182-.659 3.841S19.621 22 17.5 22s-3.182 0-3.841-.659S13 19.621 13 17.5"
                opacity=".5"
            />
            <path
                d="M2 17.5c0-2.121 0-3.182.659-3.841S4.379 13 6.5 13s3.182 0 3.841.659S11 15.379 11 17.5s0 3.182-.659 3.841S8.621 22 6.5 22s-3.182 0-3.841-.659S2 19.621 2 17.5m11-11c0-2.121 0-3.182.659-3.841S15.379 2 17.5 2s3.182 0 3.841.659S22 4.379 22 6.5s0 3.182-.659 3.841S19.621 11 17.5 11s-3.182 0-3.841-.659S13 8.621 13 6.5"
            />
        </svg>
    );
}

export function BoxIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                d="M8.422 20.618C10.178 21.54 11.056 22 12 22V12L2.638 7.073l-.04.067C2 8.154 2 9.417 2 11.942v.117c0 2.524 0 3.787.597 4.801.598 1.015 1.674 1.58 3.825 2.709z"
            />
            <path
                d="m17.577 4.432l-2-1.05C13.822 2.461 12.944 2 12 2c-.945 0-1.822.46-3.578 1.382l-2 1.05C4.318 5.536 3.242 6.1 2.638 7.072L12 12l9.362-4.927c-.606-.973-1.68-1.537-3.785-2.641"
                opacity=".7"
            />
            <path
                d="m21.403 7.14l-.041-.067L12 12v10c.944 0 1.822-.46 3.578-1.382l2-1.05c2.151-1.129 3.227-1.693 3.825-2.708.597-1.014.597-2.277.597-4.8v-.117c0-2.525 0-3.788-.597-4.802"
                opacity=".5"
            />
        </svg>
    );
}

export function UsersIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <circle cx="15" cy="6" r="3" opacity=".4" />
            <ellipse cx="16" cy="17" opacity=".4" rx="5" ry="3" />
            <circle cx="9.001" cy="6" r="4" />
            <ellipse cx="9.001" cy="17.001" rx="7" ry="4" />
        </svg>
    );
}

export function HeartPulseIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                d="M2 16c0-2.828 0-4.243.879-5.121C3.757 10 5.172 10 8 10h8c2.828 0 4.243 0 5.121.879C22 11.757 22 13.172 22 16s0 4.243-.879 5.121C20.243 22 18.828 22 16 22H8c-2.828 0-4.243 0-5.121-.879C2 20.243 2 18.828 2 16"
                opacity=".5"
            />
            <path d="M12 18a2 2 0 1 0 0-4a2 2 0 0 0 0 4M6.75 8a5.25 5.25 0 0 1 10.5 0v2.004c.567.005 1.064.018 1.5.05V8a6.75 6.75 0 0 0-13.5 0v2.055a24 24 0 0 1 1.5-.051z" />
        </svg>
    );
}

export function RefreshIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                fill="none"
                stroke="currentColor"
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="1.5"
                d="M20 12a8 8 0 1 1-2.343-5.657"
            />
            <path
                fill="currentColor"
                d="M18.5 2.5v4a.75.75 0 0 1-.75.75h-4a.75.75 0 0 1 0-1.5h2.55A8 8 0 0 0 4 12h1.5A6.5 6.5 0 0 1 16.63 6.63V4.5a.75.75 0 0 1 1.5 0z"
                opacity=".6"
            />
        </svg>
    );
}

export function ImageIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                d="M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2S2 6.477 2 12s4.477 10 10 10"
                opacity=".5"
            />
            <circle cx="9" cy="9" r="2" />
            <path d="m3 19 4.092-4.092a2 2 0 0 1 2.829 0l2.242 2.243a2 2 0 0 0 2.828 0L21 11" />
        </svg>
    );
}

export function DownloadIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                d="M4 15.5a7.002 7.002 0 0 1 13.52-1.095A4.5 4.5 0 0 1 17.5 22H4a4 4 0 0 1 0-8z"
                opacity=".5"
            />
            <path
                d="M12 4.75a.75.75 0 0 1 .75.75v6.19l1.72-1.72a.75.75 0 1 1 1.06 1.06l-3 3a.75.75 0 0 1-1.06 0l-3-3a.75.75 0 1 1 1.06-1.06l1.72 1.72V5.5a.75.75 0 0 1 .75-.75"
            />
        </svg>
    );
}

export function GearIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                fillRule="evenodd"
                d="M14.279 2.152C13.909 2 13.439 2 12.5 2s-1.408 0-1.779.152a2 2 0 0 0-1.09 1.083c-.094.223-.13.484-.145.863a1.62 1.62 0 0 1-.796 1.353a1.64 1.64 0 0 1-1.579.008c-.338-.178-.583-.276-.825-.308a2.03 2.03 0 0 0-1.49.396c-.318.242-.553.646-1.022 1.453c-.47.807-.704 1.21-.757 1.605c-.07.526.074 1.058.4 1.479c.148.192.357.353.68.555c.477.297.783.803.783 1.361s-.306 1.064-.782 1.36c-.324.203-.533.364-.682.556a2 2 0 0 0-.399 1.479c.053.394.287.798.757 1.605s.704 1.21 1.022 1.453c.424.323.96.465 1.49.396c.242-.032.487-.13.825-.308a1.64 1.64 0 0 1 1.58.008c.486.28.774.795.795 1.353c.015.38.051.64.145.863c.204.49.596.88 1.09 1.083c.37.152.84.152 1.779.152s1.409 0 1.779-.152a2 2 0 0 0 1.09-1.083c.094-.223.13-.483.145-.863c.02-.558.309-1.074.796-1.353a1.64 1.64 0 0 1 1.579-.008c.338.178.583.276.825.308c.53.07 1.066-.073 1.49-.396c.318-.242.553-.646 1.022-1.453c.47-.807.704-1.21.757-1.605a2 2 0 0 0-.4-1.479c-.148-.192-.357-.353-.68-.555c-.477-.297-.783-.803-.783-1.361s.306-1.064.782-1.36c.324-.203.533-.364.682-.556a2 2 0 0 0 .399-1.479c-.053-.394-.287-.798-.757-1.605s-.704-1.21-1.022-1.453a2.03 2.03 0 0 0-1.49-.396c-.242.032-.487.13-.825.308a1.64 1.64 0 0 1-1.58-.008a1.62 1.62 0 0 1-.795-1.353c-.015-.38-.051-.64-.145-.863a2 2 0 0 0-1.09-1.083"
                clipRule="evenodd"
                opacity=".5"
            />
            <path d="M15.523 12c0 1.657-1.354 3-3.023 3s-3.023-1.343-3.023-3S10.83 9 12.5 9s3.023 1.343 3.023 3" />
        </svg>
    );
}

export function LogoutIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                d="M16 2h-1c-2.829 0-4.242 0-5.121.879S9 5.172 9 8v8c0 2.829 0 4.243.879 5.122c.878.878 2.292.878 5.119.878H16c2.828 0 4.242 0 5.121-.879C22 20.243 22 18.828 22 16V8c0-2.828 0-4.243-.879-5.121S18.828 2 16 2"
                opacity=".5"
            />
            <path
                fillRule="evenodd"
                d="M15.75 12a.75.75 0 0 0-.75-.75H4.027l1.961-1.68a.75.75 0 1 0-.976-1.14l-3.5 3a.75.75 0 0 0 0 1.14l3.5 3a.75.75 0 1 0 .976-1.14l-1.96-1.68H15a.75.75 0 0 0 .75-.75"
                clipRule="evenodd"
            />
        </svg>
    );
}

export function MenuIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                fill="none"
                stroke="currentColor"
                strokeLinecap="round"
                strokeWidth="1.5"
                d="M20 7H4m16 5H4m16 5H4"
            />
        </svg>
    );
}

export function SearchIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <g fill="none" stroke="currentColor" strokeWidth="1.5">
                <circle cx="11.5" cy="11.5" r="9.5" />
                <path strokeLinecap="round" d="M18.5 18.5L22 22" />
            </g>
        </svg>
    );
}

export function SunIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <g fill="none" stroke="currentColor" strokeWidth="1.5">
                <circle cx="12" cy="12" r="6" />
                <path strokeLinecap="round" d="M12 2v1m0 18v1m10-10h-1M3 12H2m17.07-7.07l-.392.393M5.322 18.678l-.393.393m14.141-.001l-.392-.393M5.322 5.322l-.393-.393" />
            </g>
        </svg>
    );
}

export function MoonIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path d="m21.067 11.857l-.642-.388zm-8.924-8.924l-.388-.642zM21.25 12A9.25 9.25 0 0 1 12 21.25v1.5c5.937 0 10.75-4.813 10.75-10.75zM12 21.25A9.25 9.25 0 0 1 2.75 12h-1.5c0 5.937 4.813 10.75 10.75 10.75zM2.75 12A9.25 9.25 0 0 1 12 2.75v-1.5C6.063 1.25 1.25 6.063 1.25 12zm12.75 2.25A5.75 5.75 0 0 1 9.75 8.5h-1.5a7.25 7.25 0 0 0 7.25 7.25zm4.925-2.781A5.75 5.75 0 0 1 15.5 14.25v1.5a7.25 7.25 0 0 0 6.21-3.505zM9.75 8.5a5.75 5.75 0 0 1 2.781-4.925l-.776-1.284A7.25 7.25 0 0 0 8.25 8.5zM12 2.75a.38.38 0 0 1-.268-.118a.3.3 0 0 1-.082-.155c-.004-.031-.002-.121.105-.186l.776 1.284c.503-.304.665-.861.606-1.299c-.062-.455-.42-1.026-1.137-1.026zm9.71 9.495c-.066.107-.156.109-.187.105a.3.3 0 0 1-.155-.082a.38.38 0 0 1-.118-.268h1.5c0-.717-.571-1.075-1.026-1.137c-.438-.059-.995.103-1.299.606z" />
        </svg>
    );
}

export function ChevronDownIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                fill="none"
                stroke="currentColor"
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="1.5"
                d="m19 9l-7 6l-7-6"
            />
        </svg>
    );
}

export function PlusIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path fill="none" stroke="currentColor" strokeLinecap="round" strokeWidth="1.5" d="M12 5v14m-7-7h14" />
        </svg>
    );
}

export function PencilIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                fill="none"
                stroke="currentColor"
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="1.5"
                d="M13.5 6.5l4 4L8 20H4v-4zM11 9l4 4"
            />
        </svg>
    );
}

export function TrashIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <g fill="none" stroke="currentColor" strokeWidth="1.5">
                <path
                    d="M3.5 6h17M9.5 3.5h5a.5.5 0 0 1 .5.5v2H9v-2a.5.5 0 0 1 .5-.5ZM19 6l-.8 13.2a2 2 0 0 1-2 1.8H7.8a2 2 0 0 1-2-1.8L5 6"
                />
                <path strokeLinecap="round" d="M10 10.5v7m4-7v7" />
            </g>
        </svg>
    );
}

export function ArrowRightIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                fillRule="evenodd"
                d="M12 2.75a9.25 9.25 0 1 0 0 18.5a9.25 9.25 0 0 0 0-18.5M1.25 12C1.25 6.063 6.063 1.25 12 1.25S22.75 6.063 22.75 12S17.937 22.75 12 22.75S1.25 17.937 1.25 12m11.22-3.53a.75.75 0 0 1 1.06 0l3 3a.75.75 0 0 1 0 1.06l-3 3a.75.75 0 1 1-1.06-1.06l1.72-1.72H8a.75.75 0 0 1 0-1.5h6.19l-1.72-1.72a.75.75 0 0 1 0-1.06"
                clipRule="evenodd"
            />
        </svg>
    );
}

export function ArrowLeftIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                fillRule="evenodd"
                d="M12 2.75a9.25 9.25 0 1 0 0 18.5a9.25 9.25 0 0 0 0-18.5M1.25 12C1.25 6.063 6.063 1.25 12 1.25S22.75 6.063 22.75 12S17.937 22.75 12 22.75S1.25 17.937 1.25 12m6.53-3.53a.75.75 0 0 1 1.06 0l3 3a.75.75 0 0 1 0 1.06l-3 3a.75.75 0 1 1-1.06-1.06l1.72-1.72H16a.75.75 0 0 1 0 1.5H9.81l1.72 1.72a.75.75 0 1 1-1.06 1.06l-3-3a.75.75 0 0 1 0-1.06Z"
                clipRule="evenodd"
            />
        </svg>
    );
}

export function CheckIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                fill="none"
                stroke="currentColor"
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="1.5"
                d="M5 13l4 4L19 7"
            />
        </svg>
    );
}

export function AlertIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <g fill="none">
                <path
                    stroke="currentColor"
                    strokeWidth="1.5"
                    d="M5.312 10.762C8.23 5.587 9.689 3 12 3s3.77 2.587 6.688 7.762l.364.644c2.425 4.3 3.638 6.45 2.542 8.022S17.786 21 12.364 21h-.728c-5.422 0-8.134 0-9.23-1.572s.117-3.722 2.542-8.022z"
                />
                <path stroke="currentColor" strokeLinecap="round" strokeWidth="1.5" d="M12 8v5" />
                <circle cx="12" cy="16" r="1" fill="currentColor" />
            </g>
        </svg>
    );
}

export function XIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <path
                fill="none"
                stroke="currentColor"
                strokeLinecap="round"
                strokeWidth="1.5"
                d="M6 6l12 12M18 6L6 18"
            />
        </svg>
    );
}

export function EyeIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <g fill="none" stroke="currentColor" strokeWidth="1.5">
                <path d="M3.275 15.296C2.425 14.192 2 13.639 2 12c0-1.64.425-2.191 1.275-3.296C4.972 6.5 7.818 4 12 4s7.028 2.5 8.725 4.704C21.575 9.81 22 10.361 22 12c0 1.64-.425 2.191-1.275 3.296C19.028 17.5 16.182 20 12 20s-7.028-2.5-8.725-4.704Z" />
                <path d="M15 12a3 3 0 1 1-6 0a3 3 0 0 1 6 0Z" />
            </g>
        </svg>
    );
}

export function MailIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <g fill="none" stroke="currentColor" strokeWidth="1.5">
                <path d="M2 12c0-3.771 0-5.657 1.172-6.828S6.229 4 10 4h4c3.771 0 5.657 0 6.828 1.172S22 8.229 22 12s0 5.657-1.172 6.828S17.771 20 14 20h-4c-3.771 0-5.657 0-6.828-1.172S2 15.771 2 12Z" />
                <path strokeLinecap="round" d="m6 8l2.159 1.8c1.837 1.53 2.755 2.295 3.841 2.295s2.005-.765 3.841-2.296L18 8" />
            </g>
        </svg>
    );
}

export function UserIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <g fill="none" stroke="currentColor" strokeWidth="1.5">
                <circle cx="12" cy="6" r="4" />
                <path d="M20 17.5c0 2.485 0 4.5-8 4.5s-8-2.015-8-4.5S7.582 13 12 13s8 2.015 8 4.5Z" />
            </g>
        </svg>
    );
}

export function HistoryIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <g fill="none" stroke="currentColor" strokeWidth="1.5">
                <circle cx="12" cy="12" r="10" />
                <path strokeLinecap="round" d="M12 7v5l3 3" />
            </g>
        </svg>
    );
}

export function ClipboardIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <g fill="none" stroke="currentColor" strokeWidth="1.5">
                <rect x="4" y="4" width="16" height="16" rx="3" />
                <path strokeLinecap="round" d="M9 9h6m-6 4h6m-6 4h3" />
            </g>
        </svg>
    );
}

export function ActivityIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <g fill="none" stroke="currentColor" strokeWidth="1.5">
                <path strokeLinecap="round" d="M2 12h4l3-8 4 16 3-8h6" />
            </g>
        </svg>
    );
}

export function BabyIcon({ className }) {
    return (
        <svg aria-hidden="true" {...base} className={className}>
            <g fill="none" stroke="currentColor" strokeWidth="1.5">
                <circle cx="12" cy="12" r="9" />
                <circle cx="9" cy="11" r="1" fill="currentColor" />
                <circle cx="15" cy="11" r="1" fill="currentColor" />
                <path strokeLinecap="round" d="M9.5 15a3 3 0 0 0 5 0" />
            </g>
        </svg>
    );
}
