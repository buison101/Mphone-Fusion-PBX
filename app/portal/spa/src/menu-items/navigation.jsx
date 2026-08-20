// assets
import DashboardOutlined from '@ant-design/icons/DashboardOutlined';
import PhoneOutlined from '@ant-design/icons/PhoneOutlined';
import HistoryOutlined from '@ant-design/icons/HistoryOutlined';
import AudioOutlined from '@ant-design/icons/AudioOutlined';
import BarChartOutlined from '@ant-design/icons/BarChartOutlined';
import ContactsOutlined from '@ant-design/icons/ContactsOutlined';
import SettingOutlined from '@ant-design/icons/SettingOutlined';

// icons
const icons = { DashboardOutlined, PhoneOutlined, HistoryOutlined, AudioOutlined, BarChartOutlined, ContactsOutlined, SettingOutlined };

// ==============================|| MENU ITEMS - NAVIGATION ||============================== //

const navigation = {
  id: 'group-portal',
  title: 'nav.group',
  type: 'group',
  children: [
    {
      id: 'overview',
      title: 'nav.overview',
      type: 'item',
      url: '/dashboard',
      icon: icons.DashboardOutlined,
      breadcrumbs: false
    },
    {
      id: 'active-calls',
      title: 'nav.calls',
      type: 'item',
      url: '/calls/active',
      icon: icons.PhoneOutlined,
      breadcrumbs: false
    },
    {
      id: 'call-history',
      title: 'nav.history',
      type: 'item',
      url: '/calls/history',
      icon: icons.HistoryOutlined,
      breadcrumbs: false
    },
    {
      id: 'recordings',
      title: 'nav.recordings',
      type: 'item',
      url: '/recordings',
      icon: icons.AudioOutlined,
      breadcrumbs: false
    },
    {
      id: 'reports',
      title: 'nav.reports',
      type: 'item',
      url: '/reports',
      icon: icons.BarChartOutlined,
      breadcrumbs: false
    },
    {
      id: 'missed-calls',
      title: 'nav.missedCalls',
      type: 'item',
      url: '/missed-calls',
      icon: icons.PhoneOutlined,
      breadcrumbs: false
    },
    {
      id: 'contacts',
      title: 'nav.contacts',
      type: 'item',
      url: '/contacts',
      icon: icons.ContactsOutlined,
      breadcrumbs: false
    },
    {
      id: 'settings',
      title: 'nav.settings',
      type: 'item',
      url: '/settings',
      icon: icons.SettingOutlined,
      breadcrumbs: false
    }
  ]
};

export default navigation;
