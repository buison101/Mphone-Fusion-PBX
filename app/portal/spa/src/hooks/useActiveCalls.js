import { useContext } from 'react';

// project imports
import { ActiveCallsContext } from 'contexts/ActiveCallsContext';

// ==============================|| HOOK - ACTIVE CALLS ||============================== //

export default function useActiveCalls() {
  const context = useContext(ActiveCallsContext);

  if (!context) throw new Error('useActiveCalls must be used inside ActiveCallsProvider');

  return context;
}
