import { useRef, useState } from 'react';

// material-ui
import ButtonBase from '@mui/material/ButtonBase';
import CardContent from '@mui/material/CardContent';
import ClickAwayListener from '@mui/material/ClickAwayListener';
import Divider from '@mui/material/Divider';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Paper from '@mui/material/Paper';
import Popper from '@mui/material/Popper';
import Stack from '@mui/material/Stack';
import Tooltip from '@mui/material/Tooltip';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import { Link } from 'react-router-dom';

// third-party
import { FormattedMessage } from 'react-intl';

// project imports
import Avatar from 'components/@extended/Avatar';
import MainCard from 'components/MainCard';
import Transitions from 'components/@extended/Transitions';
import useSession from 'hooks/useSession';
import { ADMIN_URL } from 'config';

// assets
import LogoutOutlined from '@ant-design/icons/LogoutOutlined';
import SettingOutlined from '@ant-design/icons/SettingOutlined';
import UserOutlined from '@ant-design/icons/UserOutlined';

// ==============================|| HEADER CONTENT - PROFILE ||============================== //
//
// Identity comes from the PHP session, and signing out hands back to the PHP
// logout so both the portal and the admin pages end the session together.

export default function Profile() {
  const { session, logout } = useSession();
  const anchorRef = useRef(null);
  const [open, setOpen] = useState(false);

  const username = session?.user?.username || '';
  const domainName = session?.domain?.domain_name || '';
  const extensions = session?.user?.extensions ?? [];
  const initial = username.charAt(0).toUpperCase() || '?';

  const handleToggle = () => setOpen((previous) => !previous);

  const handleClose = (event) => {
    if (anchorRef.current && anchorRef.current.contains(event.target)) return;
    setOpen(false);
  };

  return (
    <Box sx={{ flexShrink: 0, ml: 0.75 }}>
      <Tooltip title={username} disableInteractive>
        <ButtonBase
          sx={(theme) => ({
            p: 0.25,
            borderRadius: 1,
            '&:focus-visible': { outline: `2px solid ${theme.vars.palette.secondary.dark}`, outlineOffset: 2 }
          })}
          aria-label="open profile"
          ref={anchorRef}
          aria-controls={open ? 'profile-grow' : undefined}
          aria-haspopup="true"
          onClick={handleToggle}
        >
          <Avatar alt={username} size="sm" type="filled" color="primary">
            {initial}
          </Avatar>
        </ButtonBase>
      </Tooltip>
      <Popper
        placement="bottom-end"
        open={open}
        anchorEl={anchorRef.current}
        role={undefined}
        transition
        disablePortal
        popperOptions={{ modifiers: [{ name: 'offset', options: { offset: [0, 9] } }] }}
      >
        {({ TransitionProps }) => (
          <Transitions type="grow" position="top-right" in={open} {...TransitionProps}>
            <Paper sx={(theme) => ({ boxShadow: theme.vars.customShadows.z1, width: 290, minWidth: 240, maxWidth: { xs: 250, md: 290 } })}>
              <ClickAwayListener onClickAway={handleClose}>
                <MainCard elevation={0} border={false} content={false}>
                  <CardContent sx={{ px: 2.5, pt: 2.5, pb: 1.5 }}>
                    <Stack direction="row" sx={{ gap: 1.25, alignItems: 'center' }}>
                      <Avatar alt={username} type="filled" color="primary" sx={{ width: 32, height: 32 }}>
                        {initial}
                      </Avatar>
                      <Stack sx={{ minWidth: 0 }}>
                        <Typography variant="h6" noWrap>
                          {username}
                        </Typography>
                        <Typography variant="body2" sx={{ color: 'text.secondary' }} noWrap>
                          {domainName}
                        </Typography>
                      </Stack>
                    </Stack>
                    {extensions.length > 0 && (
                      <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', mt: 1.5 }}>
                        <FormattedMessage id="profile.extensions" values={{ list: extensions.map((row) => row.extension).join(', ') }} />
                      </Typography>
                    )}
                  </CardContent>
                  <Divider />
                  <List sx={{ p: 0, '& .MuiListItemButton-root': { py: 1.25, px: 2.5 } }}>
                    {session?.identity && (
                      <ListItemButton component={Link} to="/account" onClick={() => setOpen(false)}>
                        <ListItemIcon>
                          <UserOutlined />
                        </ListItemIcon>
                        <ListItemText primary={<FormattedMessage id="profile.account" />} />
                      </ListItemButton>
                    )}
                    {!session?.identity && (
                      <ListItemButton component="a" href={ADMIN_URL}>
                        <ListItemIcon>
                          <SettingOutlined />
                        </ListItemIcon>
                        <ListItemText primary={<FormattedMessage id="profile.admin" />} />
                      </ListItemButton>
                    )}
                    <ListItemButton onClick={logout}>
                      <ListItemIcon>
                        <LogoutOutlined />
                      </ListItemIcon>
                      <ListItemText primary={<FormattedMessage id="profile.signOut" />} />
                    </ListItemButton>
                  </List>
                </MainCard>
              </ClickAwayListener>
            </Paper>
          </Transitions>
        )}
      </Popper>
    </Box>
  );
}
