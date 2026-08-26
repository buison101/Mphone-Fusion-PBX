import { useEffect, useRef, useState } from 'react';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import { FormattedMessage } from 'react-intl';
import PropTypes from 'prop-types';
import QRCode from 'qrcode';

import { createVietQrPayload } from 'lib/vietqr';

export default function VietQrCode({ bank, period }) {
  const canvasRef = useRef(null);
  const [error, setError] = useState(false);
  useEffect(() => {
    try {
      const payload = createVietQrPayload({ bankBin: bank.bin, accountNumber: bank.account,
        amount: Math.round(Number(period.total_amount)), purpose: period.payment_code });
      QRCode.toCanvas(canvasRef.current, payload, { width: 248, margin: 2, errorCorrectionLevel: 'M' })
        .then(() => setError(false)).catch(() => setError(true));
    } catch { setError(true); }
  }, [bank, period]);
  const download = () => {
    const link = document.createElement('a');
    link.download = `vietqr-${period.payment_code}.png`;
    link.href = canvasRef.current.toDataURL('image/png');
    link.click();
  };
  if (error) return <Alert severity="error"><FormattedMessage id="billing.qrError" /></Alert>;
  return <Stack spacing={1} alignItems="center">
    <canvas ref={canvasRef} aria-label="VietQR" />
    <Typography fontWeight={600}>{period.payment_code}</Typography>
    <Button variant="outlined" onClick={download}><FormattedMessage id="billing.downloadQr" /></Button>
  </Stack>;
}

VietQrCode.propTypes = {
  bank: PropTypes.shape({ bin: PropTypes.string, account: PropTypes.string }).isRequired,
  period: PropTypes.shape({ payment_code: PropTypes.string, total_amount: PropTypes.oneOfType([PropTypes.string, PropTypes.number]) }).isRequired
};
