import useSWR from 'swr';

async function fetcher(url) {
  const response = await fetch(url, { credentials: 'same-origin', headers: { Accept: 'application/json' } });
  if (response.status === 401) {
    window.location.reload();
    return null;
  }
  if (!response.ok) throw new Error(`analytics request failed (${response.status})`);
  return response.json();
}

export default function useAnalytics(url, filters = {}) {
  const parameters = new URLSearchParams();
  Object.entries(filters).forEach(([key, value]) => {
    if (value !== '' && value !== null && value !== undefined) parameters.set(key, String(value));
  });
  const key = `${url}?${parameters}`;
  const { data, error, isLoading, mutate } = useSWR(key, fetcher, { keepPreviousData: true, revalidateOnFocus: false });
  return { data, error, isLoading, refresh: mutate };
}
