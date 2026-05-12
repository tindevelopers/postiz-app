'use client';

import { FC } from 'react';
import { resolveMediaPublicUrl } from '@gitroom/react/helpers/use.media.directory';
export const VideoFrame: FC<{
  url: string;
  autoplay?: boolean;
}> = (props) => {
  const { url } = props;
  const resolved = resolveMediaPublicUrl(url);
  return (
    <video
      className="w-full h-full object-cover rounded-[4px]"
      src={resolved + '#t=0.1'}
      preload="metadata"
      autoPlay={!!props?.autoplay}
    />
  );
};
