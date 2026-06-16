import { api } from '../api'
import { useResource } from '../useResource'
import { Panel, StatusBadge, Loading, ErrorState, Empty } from '../components/ui'

export default function Facilities() {
  const { data, loading, error, reload } = useResource(api.facilities)

  if (loading) return <Panel title="Facilities"><Loading /></Panel>
  if (error) return <Panel title="Facilities"><ErrorState message={error} onRetry={reload} /></Panel>

  return (
    <Panel title="Facilities" sub={`${data.length} licensed facilities`}>
      {data.length === 0 ? (
        <Empty />
      ) : (
        <table>
          <thead>
            <tr>
              <th>Hospital Name</th>
              <th>Location</th>
              <th>Radiation Class</th>
              <th>Equipment Classes</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {data.map((f) => (
              <tr key={f.id}>
                <td className="primary-cell">
                  {f.hospital_name}
                  {f.license_number && (
                    <div className="muted" style={{ fontSize: 12 }}>{f.license_number}</div>
                  )}
                </td>
                <td>{f.location}</td>
                <td><span className="badge blue">{f.facility_class}</span></td>
                <td>
                  <div className="chips">
                    {(f.equipment_classes || []).map((c) => (
                      <span className="chip" key={c}>{c}</span>
                    ))}
                  </div>
                </td>
                <td><StatusBadge value={f.status} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </Panel>
  )
}
