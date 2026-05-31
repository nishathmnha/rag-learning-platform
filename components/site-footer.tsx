function StackBadge({
  label,
  icon,
}: {
  label: string;
  icon: React.ReactNode;
}) {
  return (
    <span className="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white/80 px-3 py-1.5 text-xs font-medium text-slate-600 shadow-sm">
      <span className="text-slate-900">{icon}</span>
      {label}
    </span>
  );
}

export function SiteFooter() {
  return (
    <footer className="border-t border-slate-200/80 bg-white/80 px-6 py-5 backdrop-blur">
      <div className="mx-auto flex max-w-6xl flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div className="space-y-1">
          <p className="text-sm font-medium text-slate-900">
            Copyright © Ahamed Nishath
          </p>
          <p className="text-xs text-slate-500">
            Built for document-grounded learning workflows and retrieval-based lesson generation.
          </p>
        </div>

        <div className="flex flex-wrap gap-2">
          <StackBadge
            label="Next.js"
            icon={
              <svg aria-hidden="true" className="h-4 w-4" viewBox="0 0 24 24" fill="none">
                <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="1.5" />
                <path
                  d="M9 8v8M9 8l6 8M15 16V8"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            }
          />
          <StackBadge
            label="PostgreSQL"
            icon={
              <svg aria-hidden="true" className="h-4 w-4" viewBox="0 0 24 24" fill="none">
                <ellipse cx="12" cy="7" rx="6" ry="3.5" stroke="currentColor" strokeWidth="1.5" />
                <path
                  d="M6 7v6.5c0 1.9 2.7 3.5 6 3.5s6-1.6 6-3.5V7"
                  stroke="currentColor"
                  strokeWidth="1.5"
                />
                <path
                  d="M6 10.5c0 1.9 2.7 3.5 6 3.5s6-1.6 6-3.5"
                  stroke="currentColor"
                  strokeWidth="1.5"
                />
              </svg>
            }
          />
          <StackBadge
            label="Prisma"
            icon={
              <svg aria-hidden="true" className="h-4 w-4" viewBox="0 0 24 24" fill="none">
                <path
                  d="M9 4h6l4 7-7 9L5 9l4-5Z"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinejoin="round"
                />
                <path d="M9 4l3 16 7-9" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
              </svg>
            }
          />
          <StackBadge
            label="OpenAI"
            icon={
              <svg aria-hidden="true" className="h-4 w-4" viewBox="0 0 24 24" fill="none">
                <path
                  d="M12 4.5 6.5 7.7v6.6l5.5 3.2 5.5-3.2V7.7 4.5"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinejoin="round"
                />
                <path
                  d="M9 6.3 15 9.7v6.6M15 6.3 9 9.7v6.6"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinejoin="round"
                />
              </svg>
            }
          />
          <StackBadge
            label="Local Vector Retrieval"
            icon={
              <svg aria-hidden="true" className="h-4 w-4" viewBox="0 0 24 24" fill="none">
                <path
                  d="M5 8h14M5 12h14M5 16h8"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                />
                <circle cx="17.5" cy="16.5" r="2.5" stroke="currentColor" strokeWidth="1.5" />
              </svg>
            }
          />
        </div>
      </div>
    </footer>
  );
}
