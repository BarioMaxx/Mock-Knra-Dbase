// Small presentational helpers shared across views.

export function Badge({ tone = 'gray', children }) {
  return <span className={`badge ${tone}`}>{children}</span>
}

const STATUS_TONES = {
  active: 'green',
  operational: 'green',
  compliant: 'green',
  pending_renewal: 'amber',
  'partial compliance': 'amber',
  maintenance: 'amber',
  under_review: 'amber',
  on_leave: 'amber',
  expired: 'red',
  suspended: 'red',
  revoked: 'red',
  'non-compliant': 'red',
  inactive: 'gray',
}

export function StatusBadge({ value }) {
  if (!value) return <span className="muted">—</span>
  const tone = STATUS_TONES[String(value).toLowerCase()] ?? 'gray'
  const label = String(value).replace(/_/g, ' ')
  return <Badge tone={tone}>{label}</Badge>
}

export function Panel({ title, sub, children }) {
  return (
    <section className="panel">
      <div className="panel-head">
        <h2>{title}</h2>
        {sub != null && <span className="sub">{sub}</span>}
      </div>
      <div className="table-wrap">{children}</div>
    </section>
  )
}

export function Loading() {
  return (
    <div className="state">
      <div className="spinner" />
      Loading records…
    </div>
  )
}

export function ErrorState({ message, onRetry }) {
  return (
    <div className="state error-box">
      <div>Could not load data.</div>
      <code>{message}</code>
      <div>
        <button className="retry" onClick={onRetry}>
          Try again
        </button>
      </div>
    </div>
  )
}

export function Empty({ children }) {
  return <div className="state">{children ?? 'No records found.'}</div>
}
