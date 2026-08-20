import PropTypes from 'prop-types';
import { createContext, useCallback, useMemo, useState } from 'react';

// third-party
import { IntlProvider } from 'react-intl';

// project imports
import en from 'locales/en.json';
import vi from 'locales/vi.json';

// ==============================|| LOCALE CONTEXT ||============================== //
//
// Both languages are first class. A new string lands in both catalogues in the
// same change, never one plus a note to translate later.

export const LocaleContext = createContext(undefined);

const MESSAGES = { en, vi };
export const LOCALES = [
  { value: 'vi', labelId: 'header.language.vi' },
  { value: 'en', labelId: 'header.language.en' }
];

const STORAGE_KEY = 'portal-locale';

// The browser preference decides the first visit, the stored choice every visit
// after that.
function initialLocale() {
  try {
    const stored = window.localStorage.getItem(STORAGE_KEY);
    if (stored && MESSAGES[stored]) return stored;
  } catch {
    // private mode or blocked storage, fall through to the browser preference
  }

  const preferred = (navigator.language || 'vi').slice(0, 2).toLowerCase();
  return MESSAGES[preferred] ? preferred : 'vi';
}

export function LocaleProvider({ children }) {
  const [locale, setLocaleState] = useState(initialLocale);

  const setLocale = useCallback((next) => {
    if (!MESSAGES[next]) return;
    setLocaleState(next);
    try {
      window.localStorage.setItem(STORAGE_KEY, next);
    } catch {
      // not being able to remember the choice is not a reason to refuse it
    }
    document.documentElement.setAttribute('lang', next);
  }, []);

  const value = useMemo(() => ({ locale, setLocale }), [locale, setLocale]);

  return (
    <LocaleContext.Provider value={value}>
      <IntlProvider locale={locale} defaultLocale="vi" messages={MESSAGES[locale]}>
        {children}
      </IntlProvider>
    </LocaleContext.Provider>
  );
}

LocaleProvider.propTypes = { children: PropTypes.node };
