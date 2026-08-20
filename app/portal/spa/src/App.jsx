import { RouterProvider } from 'react-router-dom';

// project imports
import router from 'routes';
import ThemeCustomization from 'themes';
import { LocaleProvider } from 'contexts/LocaleContext';
import { SessionProvider } from 'contexts/SessionContext';
import { ActiveCallsProvider } from 'contexts/ActiveCallsContext';
import SessionGate from 'components/SessionGate';

// ==============================|| APP - THEME, LOCALE, SESSION, ROUTER ||============================== //

export default function App() {
  return (
    <ThemeCustomization>
      <LocaleProvider>
        <SessionProvider>
          <SessionGate>
            <ActiveCallsProvider>
              <RouterProvider router={router} />
            </ActiveCallsProvider>
          </SessionGate>
        </SessionProvider>
      </LocaleProvider>
    </ThemeCustomization>
  );
}
