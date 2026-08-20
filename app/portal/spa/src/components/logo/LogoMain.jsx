// material-ui
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

// ==============================|| LOGO - MAIN ||============================== //

export default function LogoMain() {
  return (
    <Stack direction="row" sx={{ gap: 1, alignItems: 'center' }}>
      <Typography variant="h4" sx={{ color: 'primary.main', fontWeight: 700, lineHeight: 1 }}>
        M
      </Typography>
      <Typography variant="h5" sx={{ fontWeight: 600, lineHeight: 1 }}>
        Mphone
      </Typography>
    </Stack>
  );
}
