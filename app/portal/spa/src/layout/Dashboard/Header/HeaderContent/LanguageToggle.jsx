import { useRef, useState } from 'react';

// material-ui
import ClickAwayListener from '@mui/material/ClickAwayListener';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import Paper from '@mui/material/Paper';
import Popper from '@mui/material/Popper';
import Tooltip from '@mui/material/Tooltip';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';

// third-party
import { FormattedMessage, useIntl } from 'react-intl';

// project imports
import IconButton from 'components/@extended/IconButton';
import MainCard from 'components/MainCard';
import Transitions from 'components/@extended/Transitions';
import useLocale from 'hooks/useLocale';
import { LOCALES } from 'contexts/LocaleContext';

// assets
import GlobalOutlined from '@ant-design/icons/GlobalOutlined';

// ==============================|| HEADER CONTENT - LANGUAGE TOGGLE ||============================== //

export default function LanguageToggle() {
  const { locale, setLocale } = useLocale();
  const intl = useIntl();
  const anchorRef = useRef(null);
  const [open, setOpen] = useState(false);

  const handleClose = (event) => {
    if (anchorRef.current && anchorRef.current.contains(event.target)) return;
    setOpen(false);
  };

  return (
    <Box sx={{ flexShrink: 0, ml: 0.75 }}>
      <Tooltip title={intl.formatMessage({ id: 'header.language.label' })} disableInteractive>
        <IconButton
          ref={anchorRef}
          color="secondary"
          variant="light"
          aria-label={intl.formatMessage({ id: 'header.language.label' })}
          aria-haspopup="true"
          onClick={() => setOpen((previous) => !previous)}
          sx={{ color: 'text.primary' }}
        >
          <GlobalOutlined />
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
                    {LOCALES.map((option) => (
                      <ListItemButton
                        key={option.value}
                        selected={locale === option.value}
                        onClick={() => {
                          setLocale(option.value);
                          setOpen(false);
                        }}
                      >
                        <ListItemText primary={<FormattedMessage id={option.labelId} />} />
                        <Typography variant="caption" sx={{ color: 'text.secondary', textTransform: 'uppercase' }}>
                          {option.value}
                        </Typography>
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
