// project imports
import { withAlpha } from 'utils/colorUtils';

// ==============================|| DEFAULT THEME - CUSTOM SHADOWS ||============================== //

export default function CustomShadows(palette) {
  // The ambient shadow is black in both schemes, as the design system tokens
  // state. It cannot be derived from grey[900]: that step is white on the dark
  // scale, which would ring every raised surface with a white glow instead of
  // shadowing it. On dark the card border carries the separation, the same way
  // it does on light where cards ship at elevation zero.
  return {
    button: `0 2px #0000000b`,
    text: `0 -1px 0 rgb(0 0 0 / 12%)`,
    z1: `0px 1px 4px ${withAlpha(palette.common.black, 0.08)}`,
    primary: `0 0 0 2px ${withAlpha(palette.primary.main, 0.2)}`,
    secondary: `0 0 0 2px ${withAlpha(palette.secondary.main, 0.2)}`,
    error: `0 0 0 2px ${withAlpha(palette.error.main, 0.2)}`,
    warning: `0 0 0 2px ${withAlpha(palette.warning.main, 0.2)}`,
    info: `0 0 0 2px ${withAlpha(palette.info.main, 0.2)}`,
    success: `0 0 0 2px ${withAlpha(palette.success.main, 0.2)}`,
    grey: `0 0 0 2px ${withAlpha(palette.grey[500], 0.2)}`,
    primaryButton: `0 14px 12px ${withAlpha(palette.primary.main, 0.2)}`,
    secondaryButton: `0 14px 12px ${withAlpha(palette.secondary.main, 0.2)}`,
    errorButton: `0 14px 12px ${withAlpha(palette.error.main, 0.2)}`,
    warningButton: `0 14px 12px ${withAlpha(palette.warning.main, 0.2)}`,
    infoButton: `0 14px 12px ${withAlpha(palette.info.main, 0.2)}`,
    successButton: `0 14px 12px ${withAlpha(palette.success.main, 0.2)}`,
    greyButton: `0 14px 12px ${withAlpha(palette.grey[500], 0.2)}`
  };
}
