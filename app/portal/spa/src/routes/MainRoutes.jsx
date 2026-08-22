import { lazy } from 'react';
import { Navigate } from 'react-router-dom';

// project imports
import Loadable from 'components/Loadable';
import DashboardLayout from 'layout/Dashboard';
import { APP_DEFAULT_PATH } from 'config';

const Overview = Loadable(lazy(() => import('pages/dashboard/Overview')));
const ActiveCalls = Loadable(lazy(() => import('pages/calls/ActiveCalls')));
const CallHistory = Loadable(lazy(() => import('pages/calls/CallHistoryPhase1')));
const Recordings = Loadable(lazy(() => import('pages/recordings/Recordings')));
const Reports = Loadable(lazy(() => import('pages/reports/Reports')));
const MissedCalls = Loadable(lazy(() => import('pages/missed/MissedCalls')));
const Contacts = Loadable(lazy(() => import('pages/contacts/Contacts')));
const Settings = Loadable(lazy(() => import('pages/settings/Settings')));
const Account = Loadable(lazy(() => import('pages/account/Account')));

// ==============================|| MAIN ROUTING ||============================== //

const MainRoutes = {
  path: '/',
  element: <DashboardLayout />,
  children: [
    {
      path: '/',
      element: <Navigate to={APP_DEFAULT_PATH} replace />
    },
    {
      path: 'recordings',
      element: <Recordings />
    },
    {
      path: 'reports',
      element: <Reports />
    },
    {
      path: 'missed-calls',
      element: <MissedCalls />
    },
    {
      path: 'contacts',
      element: <Contacts />
    },
    {
      path: 'settings',
      element: <Settings />
    },
    {
      path: 'account',
      element: <Account />
    },
    {
      path: 'dashboard',
      element: <Overview />
    },
    {
      path: 'calls',
      children: [
        {
          path: 'active',
          element: <ActiveCalls />
        },
        {
          path: 'history',
          element: <CallHistory />
        }
      ]
    },
    {
      path: '*',
      element: <Navigate to={APP_DEFAULT_PATH} replace />
    }
  ]
};

export default MainRoutes;
