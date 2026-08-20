// third-party
import { presetPalettes, presetDarkPalettes } from '@ant-design/colors';

// project imports
import ThemeOption from './theme';
import { extendPaletteWithChannels } from 'utils/colorUtils';

// ==============================|| GREY COLORS BUILDER ||============================== //
//
// The dark scale is the light one inverted: index 0 is the darkest step, 900 the
// lightest. Values come from the Mantis design system reference under
// uiux-demo/mantis-free/.../mantis-design-system and were verified to reproduce
// mantis-tokens.json exactly when fed through ThemeOption.

function buildGrey(mode) {
  if (mode === 'dark') {
    const greyPrimary = [
      '#000000',
      '#141414',
      '#1f1f1f',
      '#262626',
      '#434343',
      '#595959',
      '#8c8c8c',
      '#bfbfbf',
      '#d9d9d9',
      '#f0f0f0',
      '#ffffff'
    ];
    const greyAscent = ['#141414', '#434343', '#bfbfbf', '#fafafa'];
    const greyConstant = ['#121212', '#1e1e1e'];
    return [...greyPrimary, ...greyAscent, ...greyConstant];
  }

  const greyPrimary = [
    '#ffffff',
    '#fafafa',
    '#f5f5f5',
    '#f0f0f0',
    '#d9d9d9',
    '#bfbfbf',
    '#8c8c8c',
    '#595959',
    '#262626',
    '#141414',
    '#000000'
  ];
  const greyAscent = ['#fafafa', '#bfbfbf', '#434343', '#1f1f1f'];
  const greyConstant = ['#fafafb', '#e6ebf1'];
  return [...greyPrimary, ...greyAscent, ...greyConstant];
}

// ==============================|| DEFAULT THEME - PALETTE ||============================== //

export function buildPalette(presetColor) {
  const commonColor = { common: { black: '#000', white: '#fff' } };
  const extendedCommon = extendPaletteWithChannels(commonColor);

  const light = extendPaletteWithChannels(ThemeOption({ ...presetPalettes, grey: buildGrey('light') }, presetColor));
  const dark = extendPaletteWithChannels(ThemeOption({ ...presetDarkPalettes, grey: buildGrey('dark') }, presetColor));

  return {
    light: {
      mode: 'light',
      ...extendedCommon,
      ...light,
      text: {
        primary: light.grey[700],
        secondary: light.grey[500],
        disabled: light.grey[400]
      },
      action: { disabled: light.grey[300] },
      divider: light.grey[200],
      background: {
        paper: light.grey[0],
        default: light.grey.A50
      }
    },
    dark: {
      mode: 'dark',
      ...extendedCommon,
      ...dark,
      text: {
        primary: 'rgba(255, 255, 255, 0.87)',
        // The reference sets this to grey[400] (#595959), which lands at 2.67:1
        // on the paper colour — below the 4.5:1 needed for body text, and darker
        // than its own disabled step. grey[500] is the next token up the same
        // scale and reaches 5.57:1, so secondary text is legible and still ranks
        // above disabled.
        secondary: dark.grey[500],
        disabled: 'rgba(255, 255, 255, 0.45)'
      },
      action: { disabled: dark.grey[300] },
      divider: 'rgba(255, 255, 255, 0.05)',
      background: {
        // mantis-tokens.css lists paper #1e1e1e and default #121212, the reverse
        // of what palette.js in the same reference computes. The computed pair is
        // used here because MainCard draws its border with grey.A800 (#1e1e1e):
        // against a #1e1e1e paper that border is invisible, against #121212 it is
        // the line that separates a card from the page.
        paper: dark.grey.A50,
        default: dark.grey.A800
      }
    }
  };
}
