import { api } from '../api'
import { useResource } from '../useResource'
import { Panel, Badge, StatusBadge, Loading, ErrorState, Empty } from '../components/ui'

function formatDate(value) {
  if (!value) return '—'
  const d = new Date(value)
  if (Number.isNaN(d.getTime())) return value
  return d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
}

function ExpiryHint({ days }) {
  if (days == null) return null
  if (days < 0) return <Badge tone="red">expired {Math.abs(days)}d ago</Badge>
  if (days <= 90) return <Badge tone="amber">in {days}d</Badge>
  return <span className="muted" style={{ fontSize: 12 }}>in {days}d</span>
}

export default function Licenses() {
  const { data, loading, error, reload } = useResource(api.licenses)

  if (loading) return <Panel title="Licenses"><Loading /></Panel>
  if (error) return <Panel title="Licenses"><ErrorState message={error} onRetry={reload} /></Panel>

  return (
    <Panel title="Licenses" sub={`${data.length} licenses`}>
      {data.length === 0 ? (
        <Empty />
      ) : (
        <table>
          <thead>
            <tr>
              <th>License No.</th>
              <th>Facility</th>
              <th>Issue Date</th>
              <th>Expiry Date</th>
              <th>Status</th>
              <th>Fee Paid</th>
            </tr>
          </thead>
          <tbody>
            {data.map((l) => (
              <tr key={l.id}>
                <td className="primary-cell">{l.license_number}</td>
                <td>{l.hospital_name}</td>
                <td>{formatDate(l.issue_date)}</td>
                <td>
                  {formatDate(l.expiry_date)}{' '}
                  <ExpiryHint days={l.days_until_expiry} />
                </td>
                <td><StatusBadge value={l.status} /></td>
                <td>
                  {l.fee_paid ? (
                    <Badge tone="green">Paid</Badge>
                  ) : (
                    <Badge tone="red">Unpaid</Badge>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </Panel>
  )
}
