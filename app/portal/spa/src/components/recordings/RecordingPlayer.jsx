import { useEffect, useRef, useState } from 'react';
import PropTypes from 'prop-types';

// material-ui
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Stack from '@mui/material/Stack';

// third-party
import { useIntl } from 'react-intl';

// project imports
import { RECORDING_URL } from 'config';

const SPEEDS = [0.75, 1, 1.25, 1.5, 2];

export default function RecordingPlayer({ callUuid, allowDownload = false, seekRequest = null }) {
  const intl = useIntl();
  const audioRef = useRef(null);
  const [speed, setSpeed] = useState(1);

  useEffect(() => {
    if (audioRef.current && seekRequest && Number.isFinite(seekRequest.seconds)) {
      audioRef.current.currentTime = Math.max(0, seekRequest.seconds);
      audioRef.current.play().catch(() => {});
    }
  }, [seekRequest]);

  const changeSpeed = (value) => {
    setSpeed(value);
    if (audioRef.current) audioRef.current.playbackRate = value;
  };

  const skip = (seconds) => {
    if (!audioRef.current) return;
    audioRef.current.currentTime = Math.max(0, audioRef.current.currentTime + seconds);
  };

  return (
    <Stack sx={{ gap: 1.25 }}>
      <Box
        ref={audioRef}
        component="audio"
        controls
        preload="metadata"
        src={`${RECORDING_URL}?id=${callUuid}`}
        sx={{ width: 1, height: 40 }}
      />
      <Stack direction="row" sx={{ gap: 0.5, flexWrap: 'wrap', alignItems: 'center' }}>
        <Button size="small" variant="outlined" onClick={() => skip(-10)}>
          −10s
        </Button>
        <Button size="small" variant="outlined" onClick={() => skip(10)}>
          +10s
        </Button>
        {SPEEDS.map((value) => (
          <Button key={value} size="small" variant={speed === value ? 'contained' : 'text'} onClick={() => changeSpeed(value)}>
            {value}×
          </Button>
        ))}
        {allowDownload && (
          <Button size="small" component="a" href={`${RECORDING_URL}?id=${callUuid}&download=1`} sx={{ ml: 'auto' }}>
            {intl.formatMessage({ id: 'history.download' })}
          </Button>
        )}
      </Stack>
    </Stack>
  );
}

RecordingPlayer.propTypes = {
  callUuid: PropTypes.string.isRequired,
  allowDownload: PropTypes.bool,
  seekRequest: PropTypes.shape({ seconds: PropTypes.number, nonce: PropTypes.number })
};
