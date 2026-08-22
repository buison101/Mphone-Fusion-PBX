// material-ui
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

// project imports
import useSession from 'hooks/useSession';
import { isMaskable, maskSx } from 'utils/brandMark';

// ==============================|| LOGO - MAIN ||============================== //
//
// The mark comes from the FusionPBX theme settings, delivered by the session
// endpoint, so the portal and the administration pages carry the same branding
// and changing the template moves both.

export default function LogoMain() {
  const { session } = useSession();
  const branding = session?.branding;
  const text = branding?.brand_text || 'Mphone';
  const source = branding?.logo;

  if (source && branding.brand_type !== 'text') {
    if (isMaskable(source)) {
      return <Box role="img" aria-label={text} sx={maskSx(source, { height: 28, width: 132 })} />;
    }

    return (
      <Box
        component="img"
        src={source}
        alt={text}
        sx={{ height: 28, maxWidth: 160, width: 'auto', objectFit: 'contain', display: 'block' }}
      />
    );
  }

  return (
    <Typography variant="h5" sx={{ fontWeight: 600, lineHeight: 1 }}>
      {text}
    </Typography>
  );
}
