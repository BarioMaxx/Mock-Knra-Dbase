import { useEffect, useState } from 'react'
import { api } from './api'
import { useResource } from './useResource'
import { Loading, ErrorState } from './components/ui'
import Facilities from './views/Facilities'
import Licenses from './views/Licenses'
import Inspectors from './views/Inspectors'

const TABS = [
  { id: 'overview', label: 'Overview' },
  { id: 'facilities', label: 'Facilities' },
  { id: 'licenses', label: 'Licenses' },
  { id: 'inspectors', label: 'Inspectors' },
]

const KPI_CARDS = [
  { key: 'total_facilities', label: 'Facilities', icon: '🏥' },
  { key: 'active_licenses', label: 'Active Licenses', icon: '📄' },
  { key: 'total_inspectors', label: 'Inspectors', icon: '🧑‍🔬' },
  { key: 'total_equipment', label: 'Equipment', icon: '⚙️' },
  { key: 'expiring_licenses_90_days', label: 'Expiring ≤90d', icon: '⏳', tone: 'warn' },
  { key: 'overdue_calibrations', label: 'Overdue Calibrations', icon: '⚠️', tone: 'danger' },
]

function HealthPill() {
  const [status, setStatus] = useState('checking')
  useEffect(() => {
    let active = true
    api
      .health()
      .then((h) => active && setStatus(h.database === 'connected' ? 'ok' : 'bad'))
      .catch(() => active && setStatus('bad'))
    return () => {
      active = false
    }
  }, [])
  const label = { checking: 'Checking…', ok: 'Database connected', bad: 'Database offline' }[status]
  const dot = { checking: '', ok: 'ok', bad: 'bad' }[status]
  return (
    <div className="health">
      <span className={`dot ${dot}`} />
      {label}
    </div>
  )
}

function Overview() {
  const { data, loading, error, reload } = useResource(api.kpis)
  if (loading) return <Loading />
  if (error) return <ErrorState message={error} onRetry={reload} />
  return (
    <div className="kpi-grid">
      {KPI_CARDS.map((card) => (
        <div className="kpi" key={card.key}>
          <span className="icon">{card.icon}</span>
          <div className="label">{card.label}</div>
          <div className={`value ${card.tone || ''}`}>{data[card.key] ?? 0}</div>
        </div>
      ))}
    </div>
  )
}

export default function App() {
  const [tab, setTab] = useState('overview')
  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <div className="logo">☢️</div>
          <div>
            <h1>KNRA Licensing Dashboard</h1>
            <p>Radioactive equipment &amp; facility licensing registry</p>
          </div>
        </div>
        <HealthPill />
      </header>

      <nav className="tabs">
        {TABS.map((t) => (
          <button
            key={t.id}
            className={`tab ${tab === t.id ? 'active' : ''}`}
            onClick={() => setTab(t.id)}
          >
            {t.label}
          </button>
        ))}
      </nav>

      {tab === 'overview' && (
        <>
          <Overview />
          <Facilities />
        </>
      )}
      {tab === 'facilities' && <Facilities />}
      {tab === 'licenses' && <Licenses />}
      {tab === 'inspectors' && <Inspectors />}

      <p className="footer">
        Kenya Nuclear Regulatory Authority · mock dataset · served via Flask REST API
      </p>
    </div>
  )
}
