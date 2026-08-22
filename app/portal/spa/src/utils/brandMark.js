// ==============================|| BRAND MARK ||============================== //
//
// FusionPBX ships two kinds of logo: an SVG drawn in white for its dark sidebar,
// and PNGs drawn in dark ink for light backgrounds. The portal drawer is white in
// light mode and near black in dark mode, so neither asset works in both — the
// white SVG simply disappears on a white drawer.
//
// A monochrome mark is therefore painted rather than displayed: the file becomes
// a CSS mask and the fill comes from the current text colour, so the shape is the
// theme's asset while the colour follows the scheme. Raster files keep their own
// colours and are shown as an ordinary image.
//
// The mask is used instead of inlining the SVG so no remote markup is ever
// injected into the document.

export function isMaskable(source) {
  return typeof source === 'string' && source.split('?')[0].toLowerCase().endsWith('.svg');
}

export function maskSx(source, { height, width }) {
  const url = `url("${encodeURI(source)}")`;

  return {
    height,
    width,
    backgroundColor: 'text.primary',
    display: 'block',
    maskImage: url,
    WebkitMaskImage: url,
    maskSize: 'contain',
    WebkitMaskSize: 'contain',
    maskRepeat: 'no-repeat',
    WebkitMaskRepeat: 'no-repeat',
    maskPosition: 'left center',
    WebkitMaskPosition: 'left center'
  };
}
