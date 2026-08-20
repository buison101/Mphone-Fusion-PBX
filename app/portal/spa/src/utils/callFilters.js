// ==============================|| CALL FILTER CONTRACT ||============================== //
//
// Values shared by call history and the future analytics screens. Authorization
// remains on the server; these constants only keep controls and request names
// consistent in the browser.

export const CALL_DIRECTIONS = ['inbound', 'outbound', 'local'];

export const CALL_RANGE_PRESETS = ['today', 'yesterday', '7d', '30d', '90d', 'custom'];

export const CALL_PAGE_SIZES = [20, 50, 100];

export const EMPTY_CALL_FILTERS = {
  q: '',
  from: '',
  to: '',
  direction: '',
  status: ''
};

export function toCallSearchParams(filters) {
  const query = new URLSearchParams();

  Object.entries(filters ?? {}).forEach(([key, value]) => {
    if (value === '' || value === null || value === undefined) return;

    if (Array.isArray(value)) {
      value.forEach((item) => query.append(key, item));
      return;
    }

    query.set(key, value);
  });

  return query;
}
