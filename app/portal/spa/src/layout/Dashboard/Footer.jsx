// material-ui
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

// ==============================|| FOOTER ||============================== //

export default function Footer() {
  return (
    <Stack
      direction={{ xs: 'column', sm: 'row' }}
      sx={{ gap: 1.5, alignItems: 'center', justifyContent: 'space-between', p: '24px 16px 0px', mt: 'auto' }}
    >
      <Typography variant="caption" sx={{ color: 'text.secondary' }}>
        &copy; {new Date().getFullYear()} Mphone
      </Typography>
    </Stack>
  );
}
