import Alert from '@mui/material/Alert';
import Chip from '@mui/material/Chip';
import Stack from '@mui/material/Stack';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Typography from '@mui/material/Typography';
import { FormattedMessage, useIntl } from 'react-intl';

import MainCard from 'components/MainCard';
import ContentState from 'components/states/ContentState';
import VietQrCode from 'components/billing/VietQrCode';
import useAnalytics from 'hooks/useAnalytics';
import { BILLING_URL } from 'config';

export default function Billing() {
  const intl = useIntl();
  const { data, error, isLoading } = useAnalytics(BILLING_URL);
  if (isLoading) return <ContentState loading />;
  if (error) return <Alert severity="error"><FormattedMessage id="billing.error" /></Alert>;
  const subscriptions = data?.subscriptions ?? [];
  const periods = data?.billing_periods ?? [];
  const payable = periods.find((item) => ['pending', 'overdue'].includes(item.status));
  const money = (value, currency = 'VND') => new Intl.NumberFormat(intl.locale, { style: 'currency', currency }).format(Number(value || 0));
  return <Stack spacing={2}>
    <Typography variant="h4"><FormattedMessage id="billing.title" /></Typography>
    <MainCard title={<FormattedMessage id="billing.subscription" />}>
      {subscriptions.length ? subscriptions.map((item) => <Stack key={item.subscription_uuid} direction={{ xs: 'column', sm: 'row' }} spacing={2}>
        <Typography>{item.display_name}</Typography><Chip size="small" label={intl.formatMessage({ id: `billing.status.${item.status}` })} />
        <Typography color="text.secondary">{money(item.total_amount, item.currency)} · {item.period_start} – {item.period_end}</Typography>
      </Stack>) : <Typography color="text.secondary"><FormattedMessage id="billing.emptySubscription" /></Typography>}
    </MainCard>
    <MainCard title={<FormattedMessage id="billing.bankTransfer" />}>
      <Typography>{data?.bank?.name} · {data?.bank?.account} · {data?.bank?.account_name}</Typography>
      <Typography color="text.secondary"><FormattedMessage id="billing.transferHelp" /></Typography>
      {payable && <VietQrCode bank={data.bank} period={payable} />}
    </MainCard>
    <MainCard title={<FormattedMessage id="billing.periods" />} content={false}>
      <TableContainer><Table><TableHead><TableRow>
        <TableCell><FormattedMessage id="billing.code" /></TableCell><TableCell><FormattedMessage id="billing.servicePeriod" /></TableCell>
        <TableCell><FormattedMessage id="billing.due" /></TableCell><TableCell align="right"><FormattedMessage id="billing.amount" /></TableCell>
        <TableCell><FormattedMessage id="billing.state" /></TableCell>
      </TableRow></TableHead><TableBody>
        {periods.map((item) => <TableRow key={item.billing_period_uuid}><TableCell>{item.payment_code}</TableCell>
          <TableCell>{item.service_from} – {item.service_until}</TableCell><TableCell>{item.due_date}</TableCell>
          <TableCell align="right">{money(item.total_amount, item.currency)}</TableCell>
          <TableCell><Chip size="small" label={intl.formatMessage({ id: `billing.status.${item.status}` })} /></TableCell></TableRow>)}
        {!periods.length && <TableRow><TableCell colSpan={5}><FormattedMessage id="billing.empty" /></TableCell></TableRow>}
      </TableBody></Table></TableContainer>
    </MainCard>
  </Stack>;
}
