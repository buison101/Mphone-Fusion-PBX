// material-ui
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';

// project import
import NavGroup from './NavGroup';
import menuItem from 'menu-items';
import useSession from 'hooks/useSession';

// ==============================|| DRAWER CONTENT - NAVIGATION ||============================== //

export default function Navigation() {
  const { session } = useSession();
  const visibleMenu = menuItem.items
    .map((item) => ({
      ...item,
      children: item.children?.filter(
        (child) =>
          (!child.requiresUserManagement || session?.user_management?.allowed) &&
          (!child.requiresSuperadmin || session?.user_management?.superadmin) &&
          (!child.requiresIdentity || Boolean(session?.identity)) &&
          (!child.allowedMembershipRoles || child.allowedMembershipRoles.includes(session?.membership?.role)) &&
          // Workspace scoping applies to Customer Identity sessions. Native
          // FusionPBX administrators retain their permission-based portal view.
          (!child.requiresWorkspace || !session?.identity || Boolean(session?.workspace?.active))
      )
    }))
    .filter((item) => item.children?.length);
  const navGroups = visibleMenu.map((item) => {
    switch (item.type) {
      case 'group':
        return <NavGroup key={item.id} item={item} />;
      default:
        return (
          <Typography key={item.id} variant="h6" sx={{ color: 'error.main', textAlign: 'center' }}>
            Fix - Navigation Group
          </Typography>
        );
    }
  });

  return <Box sx={{ pt: 2 }}>{navGroups}</Box>;
}
