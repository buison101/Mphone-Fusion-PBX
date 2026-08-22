// material-ui
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

// project imports
import useSession from 'hooks/useSession';
import { isMaskable, maskSx } from 'utils/brandMark';

// ==============================|| LOGO - ICON ||============================== //
//
// Shown when the drawer is collapsed. FusionPBX keeps a separate contracted mark;
// when it is not configured the first letter of the brand stands in rather than
// squeezing a wide logo into the mini drawer.

export default function LogoIcon() {
  const { session } = useSession();
  const branding = session?.branding;
  const text = branding?.brand_text || 'Mphone';
  const source = branding?.logo_icon;

  if (source && branding.brand_type !== 'text') {
    if (isMaskable(source)) {
      return <Box role="img" aria-label={text} sx={maskSx(source, { height: 28, width: 32 })} />;
    }

    return (
      <Box
        component="img"
        src={source}
        alt={text}
        sx={{ height: 28, maxWidth: 36, width: 'auto', objectFit: 'contain', display: 'block' }}
      />
    );
  }

  return (
    <Typography variant="h4" sx={{ color: 'primary.main', fontWeight: 700, lineHeight: 1 }}>
      {text.charAt(0).toUpperCase()}
    </Typography>
  );
}
