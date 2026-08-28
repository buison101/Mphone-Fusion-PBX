import PropTypes from 'prop-types';
import { useRef, useState } from 'react';

import Box from '@mui/material/Box';
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
import Tab from '@mui/material/Tab';
import Tabs from '@mui/material/Tabs';
import Tooltip from '@mui/material/Tooltip';
import Typography from '@mui/material/Typography';
import { Link } from 'react-router-dom';

import { FormattedMessage, useIntl } from 'react-intl';

import Avatar from 'components/@extended/Avatar';
import MainCard from 'components/MainCard';
import Transitions from 'components/@extended/Transitions';
import useSession from 'hooks/useSession';
import { ADMIN_URL } from 'config';

import CreditCardOutlined from '@ant-design/icons/CreditCardOutlined';
import LogoutOutlined from '@ant-design/icons/LogoutOutlined';
import SettingOutlined from '@ant-design/icons/SettingOutlined';
import TeamOutlined from '@ant-design/icons/TeamOutlined';
import UserOutlined from '@ant-design/icons/UserOutlined';

function TabPanel({ children, value, index }) {
  return (
    <Box role="tabpanel" hidden={value !== index} id={`profile-tabpanel-${index}`} aria-labelledby={`profile-tab-${index}`}>
      {value === index && children}
    </Box>
  );
}

TabPanel.propTypes = { children: PropTypes.node, value: PropTypes.number, index: PropTypes.number };

const tabProps = (index) => ({ id: `profile-tab-${index}`, 'aria-controls': `profile-tabpanel-${index}` });

export default function Profile() {
  const { session, logout } = useSession();
  const intl = useIntl();
  const anchorRef = useRef(null);
  const [open, setOpen] = useState(false);
  const [tab, setTab] = useState(0);

  const username = session?.user?.username || '';
  const email = session?.identity?.primary_email || session?.domain?.domain_name || '';
  const extensions = session?.user?.extensions ?? [];
  const customerName = session?.customer?.display_name || session?.customer?.legal_name || '';
  const membershipRole = session?.membership?.role || '';
  const hasWorkspace = Boolean(session?.workspace?.active);
  const canManageWorkspace = Boolean(session?.user_management?.allowed);
  const canViewBilling = ['owner', 'billing_admin'].includes(membershipRole);
  const initial = (username || email).charAt(0).toUpperCase() || '?';

  const close = () => setOpen(false);
  const handleClickAway = (event) => {
    if (anchorRef.current && anchorRef.current.contains(event.target)) return;
    close();
  };

  const menuItemSx = {
    py: 1.25,
    px: 2.5,
    '& .MuiListItemIcon-root': { minWidth: 36 },
    '& .MuiListItemText-secondary': { mt: 0.25 }
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
          aria-label={intl.formatMessage({ id: 'profile.open' })}
          ref={anchorRef}
          aria-controls={open ? 'profile-grow' : undefined}
          aria-haspopup="true"
          aria-expanded={open}
          onClick={() => setOpen((previous) => !previous)}
        >
          <Avatar alt={username} size="sm" type="filled" color="primary">
            {initial}
          </Avatar>
        </ButtonBase>
      </Tooltip>
      <Popper
        id="profile-grow"
        placement="bottom-end"
        open={open}
        anchorEl={anchorRef.current}
        transition
        disablePortal
        popperOptions={{ modifiers: [{ name: 'offset', options: { offset: [0, 9] } }] }}
        sx={{ zIndex: 1300 }}
      >
        {({ TransitionProps }) => (
          <Transitions type="grow" position="top-right" in={open} {...TransitionProps}>
            <Paper
              sx={(theme) => ({
                boxShadow: theme.vars.customShadows.z1,
                width: { xs: 'calc(100vw - 32px)', sm: 380 },
                maxWidth: 380,
                maxHeight: 'calc(100vh - 88px)',
                overflowY: 'auto'
              })}
            >
              <ClickAwayListener onClickAway={handleClickAway}>
                <MainCard elevation={0} border={false} content={false}>
                  <CardContent sx={{ px: 2.5, py: 2.25 }}>
                    <Stack direction="row" sx={{ gap: 1.5, alignItems: 'center' }}>
                      <Avatar alt={username} type="filled" color="primary" sx={{ width: 40, height: 40 }}>
                        {initial}
                      </Avatar>
                      <Stack sx={{ minWidth: 0 }}>
                        <Typography variant="h5" noWrap>
                          {username}
                        </Typography>
                        <Typography variant="body2" sx={{ color: 'text.secondary' }} noWrap>
                          {email}
                        </Typography>
                      </Stack>
                    </Stack>
                    {extensions.length > 0 && (
                      <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', mt: 1.25 }}>
                        <FormattedMessage id="profile.extensions" values={{ list: extensions.map((row) => row.extension).join(', ') }} />
                      </Typography>
                    )}
                  </CardContent>

                  <Box sx={{ borderTop: 1, borderBottom: 1, borderColor: 'divider' }}>
                    <Tabs
                      variant="fullWidth"
                      value={tab}
                      onChange={(_, value) => setTab(value)}
                      aria-label={intl.formatMessage({ id: 'profile.tabs' })}
                    >
                      <Tab
                        icon={<UserOutlined />}
                        iconPosition="start"
                        label={<FormattedMessage id="profile.tab.account" />}
                        {...tabProps(0)}
                      />
                      <Tab
                        icon={<TeamOutlined />}
                        iconPosition="start"
                        label={<FormattedMessage id="profile.tab.workspace" />}
                        {...tabProps(1)}
                      />
                    </Tabs>
                  </Box>

                  <TabPanel value={tab} index={0}>
                    <List disablePadding>
                      {session?.identity ? (
                        <>
                          <ListItemButton component={Link} to="/account" onClick={close} sx={menuItemSx}>
                            <ListItemIcon>
                              <UserOutlined />
                            </ListItemIcon>
                            <ListItemText
                              primary={<FormattedMessage id="profile.personal" />}
                              secondary={<FormattedMessage id="profile.personalDetail" />}
                            />
                          </ListItemButton>
                          <ListItemButton component={Link} to="/account" onClick={close} sx={menuItemSx}>
                            <ListItemIcon>
                              <SettingOutlined />
                            </ListItemIcon>
                            <ListItemText
                              primary={<FormattedMessage id="profile.security" />}
                              secondary={<FormattedMessage id="profile.securityDetail" />}
                            />
                          </ListItemButton>
                        </>
                      ) : (
                        <ListItemButton component="a" href={ADMIN_URL} sx={menuItemSx}>
                          <ListItemIcon>
                            <SettingOutlined />
                          </ListItemIcon>
                          <ListItemText
                            primary={<FormattedMessage id="profile.admin" />}
                            secondary={<FormattedMessage id="profile.adminDetail" />}
                          />
                        </ListItemButton>
                      )}
                    </List>
                  </TabPanel>

                  <TabPanel value={tab} index={1}>
                    {hasWorkspace ? (
                      <>
                        <Box sx={{ px: 2.5, py: 1.5, bgcolor: 'action.hover' }}>
                          <Typography variant="caption" sx={{ color: 'text.secondary', textTransform: 'uppercase' }}>
                            <FormattedMessage id="profile.currentWorkspace" />
                          </Typography>
                          <Typography variant="h6" noWrap sx={{ mt: 0.25 }}>
                            {customerName}
                          </Typography>
                          {membershipRole && (
                            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                              <FormattedMessage
                                id="workspaces.role"
                                values={{ role: intl.formatMessage({ id: `workspaces.roles.${membershipRole}` }) }}
                              />
                            </Typography>
                          )}
                        </Box>
                        <List disablePadding>
                          <ListItemButton component={Link} to="/customer/profile" onClick={close} sx={menuItemSx}>
                            <ListItemIcon>
                              <TeamOutlined />
                            </ListItemIcon>
                            <ListItemText
                              primary={<FormattedMessage id="nav.customerProfile" />}
                              secondary={<FormattedMessage id="profile.workspaceDetail" />}
                            />
                          </ListItemButton>
                          {canManageWorkspace && (
                            <ListItemButton component={Link} to="/customer/members" onClick={close} sx={menuItemSx}>
                              <ListItemIcon>
                                <UserOutlined />
                              </ListItemIcon>
                              <ListItemText
                                primary={<FormattedMessage id="nav.members" />}
                                secondary={<FormattedMessage id="profile.membersDetail" />}
                              />
                            </ListItemButton>
                          )}
                          {canViewBilling && (
                            <ListItemButton component={Link} to="/billing" onClick={close} sx={menuItemSx}>
                              <ListItemIcon>
                                <CreditCardOutlined />
                              </ListItemIcon>
                              <ListItemText
                                primary={<FormattedMessage id="nav.billing" />}
                                secondary={<FormattedMessage id="profile.billingDetail" />}
                              />
                            </ListItemButton>
                          )}
                          <ListItemButton component={Link} to="/customers" onClick={close} sx={menuItemSx}>
                            <ListItemIcon>
                              <SettingOutlined />
                            </ListItemIcon>
                            <ListItemText
                              primary={<FormattedMessage id="workspaces.switch" />}
                              secondary={<FormattedMessage id="profile.switchDetail" />}
                            />
                          </ListItemButton>
                        </List>
                      </>
                    ) : (
                      <Box sx={{ px: 2.5, py: 3, textAlign: 'center' }}>
                        <Typography variant="h6">
                          <FormattedMessage id="workspaces.empty.title" />
                        </Typography>
                        <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.75, mb: 2 }}>
                          <FormattedMessage id="workspaces.empty.description" />
                        </Typography>
                        <ListItemButton component={Link} to="/customers" onClick={close} sx={{ ...menuItemSx, justifyContent: 'center' }}>
                          <ListItemText primary={<FormattedMessage id="nav.workspaces" />} sx={{ flex: '0 1 auto' }} />
                        </ListItemButton>
                      </Box>
                    )}
                  </TabPanel>

                  <Divider />
                  <List disablePadding>
                    <ListItemButton onClick={logout} sx={{ ...menuItemSx, color: 'error.main' }}>
                      <ListItemIcon sx={{ color: 'error.main' }}>
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
