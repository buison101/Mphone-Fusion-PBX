import useSWR from 'swr';

// project imports
import { DASHBOARD_URL } from 'config';

// ==============================|| HOOK - DASHBOARD ||============================== //
//
// Call history for the dashboard. The live call state comes from the websocket,
// this covers what the switch cannot report: what already happened.
//
// A 401 means the PHP session ended while the page was open, so the browser is
// sent back to the login rather than left showing stale numbers.

async function fetcher(url) {
  const response = await fetch(url, { credentials: 'same-origin', headers: { Accept: 'application/json' } });

  if (response.status === 401) {
    window.location.reload();
    return null;
  }

  if (!response.ok) throw new Error(`dashboard request failed (${response.status})`);

  return response.json();
}

export default function useDashboard(hours = 24, direction = '') {
  const parameters = new URLSearchParams({ hours: String(hours) });
  if (direction) parameters.set('direction', direction);

  const { data, error, isLoading, mutate } = useSWR(`${DASHBOARD_URL}?${parameters}`, fetcher, {
    // history moves slowly, a minute is frequent enough and keeps the database quiet
    refreshInterval: 60000,
    revalidateOnFocus: true,
    keepPreviousData: true
  });

  return { data, error, isLoading, refresh: mutate };
}
