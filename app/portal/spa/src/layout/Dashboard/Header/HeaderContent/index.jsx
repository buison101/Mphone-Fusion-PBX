// material-ui
import useMediaQuery from '@mui/material/useMediaQuery';
import Box from '@mui/material/Box';

// project imports
import Profile from './Profile';
import MobileSection from './MobileSection';
import ConnectionStatus from './ConnectionStatus';
import ThemeToggle from './ThemeToggle';
import LanguageToggle from './LanguageToggle';

// ==============================|| HEADER - CONTENT ||============================== //

export default function HeaderContent() {
  const downLG = useMediaQuery((theme) => theme.breakpoints.down('lg'));

  return (
    <>
      <Box sx={{ width: '100%', ml: 1 }} />
      <ConnectionStatus />
      <LanguageToggle />
      <ThemeToggle />
      {!downLG && <Profile />}
      {downLG && <MobileSection />}
    </>
  );
}
