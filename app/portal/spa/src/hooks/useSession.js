import { useContext } from 'react';

// project imports
import { SessionContext } from 'contexts/SessionContext';

// ==============================|| HOOK - SESSION ||============================== //

export default function useSession() {
  const context = useContext(SessionContext);

  if (!context) throw new Error('useSession must be used inside SessionProvider');

  return context;
}
