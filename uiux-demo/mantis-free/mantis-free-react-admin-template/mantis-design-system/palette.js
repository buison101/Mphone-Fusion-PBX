// =============================================================================
//  DROP-IN THAY THẾ cho  vite/src/themes/palette.js  của Mantis Free v2.2.0
//  Thêm color scheme "dark" — thứ bản Free không có và bản Pro có.
//  Giá trị sinh ra đã đối chiếu khớp với demo Pro (mantisdashboard.com):
//    primary #1668dc · warning #d89614 · error #a61d24 · success #49aa19
// =============================================================================

// third-party
import { presetPalettes, presetDarkPalettes } from '@ant-design/colors';

// project imports
import ThemeOption from './theme';
import { extendPaletteWithChannels } from 'utils/colorUtils';

// ==============================|| GREY COLORS BUILDER ||============================== //

function buildGrey(mode) {
  if (mode === 'dark') {
    // Thang grey đảo ngược: index 0 là tối nhất, 900 là sáng nhất
    const greyPrimary = [
      '#000000', '#141414', '#1f1f1f', '#262626', '#434343',
      '#595959', '#8c8c8c', '#bfbfbf', '#d9d9d9', '#f0f0f0', '#ffffff'
    ];
    const greyAscent = ['#141414', '#434343', '#bfbfbf', '#fafafa'];
    const greyConstant = ['#121212', '#1e1e1e'];
    return [...greyPrimary, ...greyAscent, ...greyConstant];
  }

  const greyPrimary = [
    '#ffffff', '#fafafa', '#f5f5f5', '#f0f0f0', '#d9d9d9',
    '#bfbfbf', '#8c8c8c', '#595959', '#262626', '#141414', '#000000'
  ];
  const greyAscent = ['#fafafa', '#bfbfbf', '#434343', '#1f1f1f'];
  const greyConstant = ['#fafafb', '#e6ebf1'];
  return [...greyPrimary, ...greyAscent, ...greyConstant];
}

// ==============================|| DEFAULT THEME - PALETTE ||============================== //

export function buildPalette(presetColor) {
  const commonColor = { common: { black: '#000', white: '#fff' } };
  const extendedCommon = extendPaletteWithChannels(commonColor);

  // ---------- LIGHT ----------
  const lightColors = { ...presetPalettes, grey: buildGrey('light') };
  const light = extendPaletteWithChannels(ThemeOption(lightColors, presetColor));

  // ---------- DARK ----------
  const darkColors = { ...presetDarkPalettes, grey: buildGrey('dark') };
  const dark = extendPaletteWithChannels(ThemeOption(darkColors, presetColor));

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
        secondary: dark.grey[400],
        disabled: 'rgba(255, 255, 255, 0.45)'
      },
      action: { disabled: dark.grey[300] },
      divider: 'rgba(255, 255, 255, 0.05)',
      background: {
        paper: dark.grey.A50,     // #1e1e1e
        default: dark.grey.A800   // #121212
      }
    }
  };
}
