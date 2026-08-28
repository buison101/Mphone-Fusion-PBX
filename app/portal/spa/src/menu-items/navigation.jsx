// assets
import DashboardOutlined from '@ant-design/icons/DashboardOutlined';
import PhoneOutlined from '@ant-design/icons/PhoneOutlined';
import HistoryOutlined from '@ant-design/icons/HistoryOutlined';
import AudioOutlined from '@ant-design/icons/AudioOutlined';
import BarChartOutlined from '@ant-design/icons/BarChartOutlined';
import ContactsOutlined from '@ant-design/icons/ContactsOutlined';
import SettingOutlined from '@ant-design/icons/SettingOutlined';
import UserOutlined from '@ant-design/icons/UserOutlined';

const workspaceRequired = { requiresWorkspace: true };
const workspaceAdminRequired = { requiresIdentity: true, requiresWorkspace: true, requiresUserManagement: true };

// Keep the drawer focused on day-to-day telephony. Personal identity, workspace
// profile and billing entry points live in the profile popper in the header.
const navigation = [
  {
    id: 'group-overview',
    title: 'nav.group.overview',
    type: 'group',
    children: [
      {
        id: 'overview',
        title: 'nav.overview',
        type: 'item',
        url: '/dashboard',
        icon: DashboardOutlined,
        ...workspaceRequired,
        breadcrumbs: false
      }
    ]
  },
  {
    id: 'group-operations',
    title: 'nav.group.operations',
    type: 'group',
    children: [
      {
        id: 'active-calls',
        title: 'nav.calls',
        type: 'item',
        url: '/calls/active',
        icon: PhoneOutlined,
        ...workspaceRequired,
        breadcrumbs: true
      },
      {
        id: 'call-history',
        title: 'nav.history',
        type: 'item',
        url: '/calls/history',
        icon: HistoryOutlined,
        ...workspaceRequired,
        breadcrumbs: false
      },
      {
        id: 'missed-calls',
        title: 'nav.missedCalls',
        type: 'item',
        url: '/missed-calls',
        icon: PhoneOutlined,
        ...workspaceRequired,
        breadcrumbs: true
      },
      {
        id: 'recordings',
        title: 'nav.recordings',
        type: 'item',
        url: '/recordings',
        icon: AudioOutlined,
        ...workspaceRequired,
        breadcrumbs: true
      },
      {
        id: 'contacts',
        title: 'nav.contacts',
        type: 'item',
        url: '/contacts',
        icon: ContactsOutlined,
        ...workspaceRequired,
        breadcrumbs: true
      }
    ]
  },
  {
    id: 'group-analysis',
    title: 'nav.group.analysis',
    type: 'group',
    children: [
      {
        id: 'reports',
        title: 'nav.reports',
        type: 'item',
        url: '/reports',
        icon: BarChartOutlined,
        ...workspaceRequired,
        breadcrumbs: true
      }
    ]
  },
  {
    id: 'group-service-admin',
    title: 'nav.group.serviceAdmin',
    type: 'group',
    children: [
      {
        id: 'members',
        title: 'nav.members',
        type: 'item',
        url: '/customer/members',
        icon: UserOutlined,
        ...workspaceAdminRequired,
        breadcrumbs: true
      },
      {
        id: 'customer-services',
        title: 'nav.customerServices',
        type: 'item',
        url: '/customer/services',
        icon: PhoneOutlined,
        ...workspaceRequired,
        breadcrumbs: true
      },
      {
        id: 'settings',
        title: 'nav.callSettings',
        type: 'item',
        url: '/settings',
        icon: SettingOutlined,
        ...workspaceRequired,
        breadcrumbs: true
      },
      {
        id: 'customer-security',
        title: 'nav.customerSecurity',
        type: 'item',
        url: '/customer/security',
        icon: SettingOutlined,
        ...workspaceAdminRequired,
        breadcrumbs: true
      }
    ]
  },
  {
    id: 'group-system-admin',
    title: 'nav.group.systemAdmin',
    type: 'group',
    children: [
      {
        id: 'system-users',
        title: 'nav.systemUsers',
        type: 'item',
        url: '/admin/users',
        icon: UserOutlined,
        requiresSuperadmin: true,
        breadcrumbs: true
      },
      {
        id: 'customers',
        title: 'nav.customers',
        type: 'item',
        url: '/customers',
        icon: ContactsOutlined,
        requiresSuperadmin: true,
        breadcrumbs: true
      }
    ]
  }
];

export default navigation;
