// Thin wrapper around the Fetch API for the KNRA backend.
// Defaults to same-origin (`/api/...`) so the dashboard works when served by
// Flask. Override with VITE_API_BASE at build time to point elsewhere.
const API_BASE = import.meta.env.VITE_API_BASE ?? ''

export async function getJSON(path) {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { Accept: 'application/json' },
  })
  if (!res.ok) {
    let detail = `Request failed (${res.status})`
    try {
      const body = await res.json()
      if (body && body.error) detail = body.error
    } catch {
      /* non-JSON error response */
    }
    throw new Error(detail)
  }
  return res.json()
}

export const api = {
  health: () => getJSON('/health'),
  kpis: () => getJSON('/api/reports/kpis'),
  facilities: () => getJSON('/api/facilities'),
  licenses: () => getJSON('/api/licenses'),
  inspectors: () => getJSON('/api/inspectors'),
}
