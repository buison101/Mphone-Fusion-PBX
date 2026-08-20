// ==============================|| CALL STATUS ||============================== //
//
// The seven values FusionPBX uses for a call. The server decides which one a row
// carries, see app/portal/resources/call_status.php — the browser only picks how
// to paint it.

export const CALL_STATUSES = ['answered', 'no_answer', 'busy', 'missed', 'voicemail', 'cancelled', 'failed'];

export const STATUS_COLOR = {
  answered: 'success',
  missed: 'error',
  no_answer: 'secondary',
  busy: 'warning',
  voicemail: 'info',
  cancelled: 'secondary',
  failed: 'error'
};
