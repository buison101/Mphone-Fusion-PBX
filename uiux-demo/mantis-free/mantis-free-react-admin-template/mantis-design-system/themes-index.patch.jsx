// =============================================================================
//  PATCH cho  vite/src/themes/index.jsx
//  Bản Free chỉ khai báo colorSchemes.light. Thêm dark để bật dark mode.
//  Chỉ cần đổi đúng khối colorSchemes + defaultMode bên dưới.
// =============================================================================

//  TRƯỚC (Free):
//
//      colorSchemes: {
//        light: {
//          palette: palette.light,
//          customShadows: CustomShadows(palette.light, 'light')
//        }
//      },
//      ...
//      <ThemeProvider ... defaultMode="light">

//  SAU (có dark, giống Pro):

      colorSchemes: {
        light: {
          palette: palette.light,
          customShadows: CustomShadows(palette.light, 'light')
        },
        dark: {
          palette: palette.dark,
          customShadows: CustomShadows(palette.dark, 'dark')
        }
      },

//      <ThemeProvider disableTransitionOnChange theme={themes}
//                     modeStorageKey="theme-mode" defaultMode="system">

//  Chuyển chế độ trong component bất kỳ:
//
//      import { useColorScheme } from '@mui/material/styles';
//      const { mode, setMode } = useColorScheme();
//      <IconButton onClick={() => setMode(mode === 'dark' ? 'light' : 'dark')} />
//
//  Lưu ý: themes/index.jsx đã bật cssVariables với colorSchemeSelector
//  'data-color-scheme', nên MUI tự gắn data-color-scheme="dark" lên <html>.
//  File mantis-tokens.css đi kèm dùng đúng selector đó — hai bên khớp nhau.
