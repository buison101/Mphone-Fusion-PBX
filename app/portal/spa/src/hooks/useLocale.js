import { useContext } from 'react';

// project imports
import { LocaleContext } from 'contexts/LocaleContext';

// ==============================|| HOOK - LOCALE ||============================== //

export default function useLocale() {
  const context = useContext(LocaleContext);

  if (!context) throw new Error('useLocale must be used inside LocaleProvider');

  return context;
}
