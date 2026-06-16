import { api } from '../api'
import { useResource } from '../useResource'
import { Panel, StatusBadge, Loading, ErrorState, Empty } from '../components/ui'

export default function Inspectors() {
  const { data, loading, error, reload } = useResource(api.inspectors)

  if (loading) return <Panel title="Inspectors"><Loading /></Panel>
  if (error) return <Panel title="Inspectors"><ErrorState message={error} onRetry={reload} /></Panel>

  return (
    <Panel title="Inspectors" sub={`${data.length} regulatory staff`}>
      {data.length === 0 ? (
        <Empty />
      ) : (
        <table>
          <thead>
            <tr>
              <th>Staff ID</th>
              <th>Inspector</th>
              <th>Assigned Facilities</th>
              <th>Inspections</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {data.map((ins) => (
              <tr key={ins.id}>
                <td className="primary-cell">{ins.staff_id}</td>
                <td>
                  {ins.full_name}
                  {ins.qualification && (
                    <div className="muted" style={{ fontSize: 12 }}>{ins.qualification}</div>
                  )}
                </td>
                <td>
                  <div className="chips">
                    {(ins.assigned_facilities || []).length === 0 ? (
                      <span className="muted">Unassigned</span>
                    ) : (
                      ins.assigned_facilities.map((name) => (
                        <span className="chip" key={name}>{name}</span>
                      ))
                    )}
                  </div>
                </td>
                <td><span className="badge blue">{ins.inspection_count}</span></td>
                <td><StatusBadge value={ins.status} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </Panel>
  )
}
