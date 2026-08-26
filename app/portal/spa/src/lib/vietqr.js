const field = (id, value) => {
  const text = String(value);
  if (text.length > 99) throw new Error('vietqr_field_too_long');
  return `${id}${String(text.length).padStart(2, '0')}${text}`;
};

const crc16 = (value) => {
  let crc = 0xffff;
  for (const byte of new TextEncoder().encode(value)) {
    crc ^= byte << 8;
    for (let bit = 0; bit < 8; bit += 1) crc = (crc & 0x8000) ? ((crc << 1) ^ 0x1021) & 0xffff : (crc << 1) & 0xffff;
  }
  return crc.toString(16).toUpperCase().padStart(4, '0');
};

export function createVietQrPayload({ bankBin, accountNumber, amount, purpose }) {
  const normalizedPurpose = String(purpose || '').toUpperCase();
  if (!/^\d{6}$/.test(String(bankBin)) || !/^\d{4,19}$/.test(String(accountNumber))) throw new Error('invalid_bank');
  if (!/^[A-Z0-9]{1,23}$/.test(normalizedPurpose)) throw new Error('invalid_purpose');
  const integerAmount = Number(amount);
  if (!Number.isSafeInteger(integerAmount) || integerAmount < 1) throw new Error('invalid_amount');
  const beneficiary = field('00', bankBin) + field('01', accountNumber);
  const merchantAccount = field('00', 'A000000727') + field('01', beneficiary) + field('02', 'QRIBFTTA');
  const additional = field('08', normalizedPurpose);
  const withoutCrc = field('00', '01') + field('01', '12') + field('38', merchantAccount) +
    field('53', '704') + field('54', integerAmount) + field('58', 'VN') + field('62', additional) + '6304';
  return withoutCrc + crc16(withoutCrc);
}
