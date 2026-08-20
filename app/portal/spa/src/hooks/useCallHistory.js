import useSWR from 'swr';

// project imports
import { CALLS_URL } from 'config';
import { toCallSearchParams } from 'utils/callFilters';

// ==============================|| HOOK - CALL HISTORY ||============================== //
//
// Paging and filtering both happen on the server. The table never receives rows
// it is not allowed to show, so there is nothing to filter out in the browser.

async function fetcher(url) {
  const response = await fetch(url, { credentials: 'same-origin', headers: { Accept: 'application/json' } });

  if (response.status === 401) {
    window.location.reload();
    return null;
  }

  if (response.status === 403) {
    const error = new Error('forbidden');
    error.forbidden = true;
    throw error;
  }

  if (!response.ok) throw new Error(`call history request failed (${response.status})`);

  return response.json();
}

export default function useCallHistory(filters) {
  const query = toCallSearchParams(filters);

  const { data, error, isLoading, mutate } = useSWR(`${CALLS_URL}?${query.toString()}`, fetcher, {
    keepPreviousData: true,
    revalidateOnFocus: false
  });

  return { data, error, isLoading, refresh: mutate, forbidden: Boolean(error?.forbidden) };
}
