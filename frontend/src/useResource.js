import { useCallback, useEffect, useState } from 'react'

// Generic data-loading hook used by every view. Tracks loading / error /
// data state and exposes a `reload` callback for the retry buttons.
export function useResource(fetcher) {
  const [data, setData] = useState(null)
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(true)

  const load = useCallback(() => {
    let active = true
    setLoading(true)
    setError(null)
    fetcher()
      .then((result) => {
        if (active) setData(result)
      })
      .catch((err) => {
        if (active) setError(err.message || String(err))
      })
      .finally(() => {
        if (active) setLoading(false)
      })
    return () => {
      active = false
    }
  }, [fetcher])

  useEffect(() => load(), [load])

  return { data, error, loading, reload: load }
}
