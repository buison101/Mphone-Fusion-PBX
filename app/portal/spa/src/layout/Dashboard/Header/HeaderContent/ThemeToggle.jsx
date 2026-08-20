import { useRef, useState } from 'react';

// material-ui
import { useColorScheme } from '@mui/material/styles';
import ClickAwayListener from '@mui/material/ClickAwayListener';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Paper from '@mui/material/Paper';
import Popper from '@mui/material/Popper';
import Tooltip from '@mui/material/Tooltip';
import Box from '@mui/material/Box';

// third-party
import { FormattedMessage, useIntl } from 'react-intl';

// project imports
import IconButton from 'components/@extended/IconButton';
import MainCard from 'components/MainCard';
import Transitions from 'components/@extended/Transitions';

// assets
import BulbOutlined from '@ant-design/icons/BulbOutlined';
import BulbFilled from '@ant-design/icons/BulbFilled';
import DesktopOutlined from '@ant-design/icons/DesktopOutlined';

// ==============================|| HEADER CONTENT - THEME TOGGLE ||============================== //
//
// Three choices rather than two: following the operating system is a real
// preference, and a customer who set their laptop to dark expects it honoured.

const OPTIONS = [
  { value: 'light', labelId: 'header.theme.light', icon: <BulbOutlined /> },
  { value: 'dark', labelId: 'header.theme.dark', icon: <BulbFilled /> },
  { value: 'system', labelId: 'header.theme.system', icon: <DesktopOutlined /> }
];

export default function ThemeToggle() {
  const { mode, setMode, systemMode } = useColorScheme();
  const intl = useIntl();
  const anchorRef = useRef(null);
  const [open, setOpen] = useState(false);

  const resolved = mode === 'system' ? systemMode : mode;

  const handleClose = (event) => {
    if (anchorRef.current && anchorRef.current.contains(event.target)) return;
    setOpen(false);
  };

  return (
    <Box sx={{ flexShrink: 0, ml: 0.75 }}>
      <Tooltip title={intl.formatMessage({ id: 'header.theme.label' })} disableInteractive>
        <IconButton
          ref={anchorRef}
          color="secondary"
          variant="light"
          aria-label={intl.formatMessage({ id: 'header.theme.label' })}
          aria-haspopup="true"
          onClick={() => setOpen((previous) => !previous)}
          sx={{ color: 'text.primary' }}
        >
          {resolved === 'dark' ? <BulbFilled /> : <BulbOutlined />}
        </IconButton>
      </Tooltip>
      <Popper
        placement="bottom-end"
        open={open}
        anchorEl={anchorRef.current}
        transition
        disablePortal
        popperOptions={{ modifiers: [{ name: 'offset', options: { offset: [0, 9] } }] }}
      >
        {({ TransitionProps }) => (
          <Transitions type="grow" position="top-right" in={open} {...TransitionProps}>
            <Paper sx={(theme) => ({ boxShadow: theme.vars.customShadows.z1, minWidth: 180 })}>
              <ClickAwayListener onClickAway={handleClose}>
                <MainCard elevation={0} border={false} content={false}>
                  <List sx={{ p: 0.5, '& .MuiListItemButton-root': { borderRadius: 1, py: 1 } }}>
                    {OPTIONS.map((option) => (
                      <ListItemButton
                        key={option.value}
                        selected={mode === option.value}
                        onClick={() => {
                          setMode(option.value);
                          setOpen(false);
                        }}
                      >
                        <ListItemIcon sx={{ minWidth: 32 }}>{option.icon}</ListItemIcon>
                        <ListItemText primary={<FormattedMessage id={option.labelId} />} />
                      </ListItemButton>
                    ))}
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
