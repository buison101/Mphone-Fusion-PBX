import { useState } from 'react';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Stack from '@mui/material/Stack';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import TextField from '@mui/material/TextField';
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
  const [topupAmount, setTopupAmount] = useState('');
  const [showTopupQr, setShowTopupQr] = useState(false);
  if (isLoading) return <ContentState loading />;
  if (error) return <Alert severity="error"><FormattedMessage id="billing.error" /></Alert>;
  const subscriptions = data?.subscriptions ?? [];
  const periods = data?.billing_periods ?? [];
  const payable = periods.find((item) => ['pending', 'overdue'].includes(item.status));
  const balance = data?.balance_account;
  const ledger = data?.balance_ledger ?? [];
  const normalizedTopupAmount = Number(topupAmount);
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
    {balance && <MainCard title={<FormattedMessage id="billing.prepaidBalance" />}>
      <Stack spacing={2}>
        <Typography variant="h3">{money(balance.available_balance, balance.currency)}</Typography>
        <Typography color="text.secondary"><FormattedMessage id="billing.topupCode" />: {balance.topup_code}</Typography>
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1} alignItems={{ sm: 'center' }}>
          <TextField type="number" value={topupAmount} label={intl.formatMessage({ id: 'billing.topupAmount' })}
            inputProps={{ min: 1, step: 1 }} onChange={(event) => { setTopupAmount(event.target.value); setShowTopupQr(false); }} />
          <Button variant="contained" disabled={!Number.isSafeInteger(normalizedTopupAmount) || normalizedTopupAmount < 1}
            onClick={() => setShowTopupQr(true)}><FormattedMessage id="billing.createTopupQr" /></Button>
        </Stack>
        {showTopupQr && <VietQrCode bank={data.bank} period={{ payment_code: balance.topup_code,
          total_amount: normalizedTopupAmount }} />}
        <Alert severity="info"><FormattedMessage id="billing.topupManualNotice" /></Alert>
      </Stack>
    </MainCard>}
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
    <MainCard title={<FormattedMessage id="billing.balanceHistory" />} content={false}>
      <TableContainer><Table><TableHead><TableRow>
        <TableCell><FormattedMessage id="billing.time" /></TableCell><TableCell><FormattedMessage id="billing.transactionType" /></TableCell>
        <TableCell align="right"><FormattedMessage id="billing.amount" /></TableCell>
        <TableCell align="right"><FormattedMessage id="billing.balanceAfter" /></TableCell>
      </TableRow></TableHead><TableBody>
        {ledger.map((item) => <TableRow key={item.ledger_entry_uuid}><TableCell>{new Date(item.occurred_at).toLocaleString(intl.locale)}</TableCell>
          <TableCell><FormattedMessage id={`billing.ledger.${item.entry_type}`} /></TableCell>
          <TableCell align="right">{item.direction === 'credit' ? '+' : '-'}{money(item.amount, item.currency)}</TableCell>
          <TableCell align="right">{money(item.balance_after, item.currency)}</TableCell></TableRow>)}
        {!ledger.length && <TableRow><TableCell colSpan={4}><FormattedMessage id="billing.balanceHistoryEmpty" /></TableCell></TableRow>}
      </TableBody></Table></TableContainer>
    </MainCard>
  </Stack>;
}
