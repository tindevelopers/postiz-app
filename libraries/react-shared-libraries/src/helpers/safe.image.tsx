'use client';

import { FC } from 'react';
import { ImageProps } from 'next/image';

type SafeImageProps = Omit<ImageProps, 'src'> & {
  src: string;
};

const SafeImage: FC<SafeImageProps> = ({
  src,
  alt,
  width,
  height,
  className,
  style,
  ...rest
}) => {
  let crossOriginReferrer: { referrerPolicy?: string } = {};
  try {
    if (
      typeof window !== 'undefined' &&
      (src.startsWith('http://') || src.startsWith('https://'))
    ) {
      const o = new URL(src).origin;
      if (o !== window.location.origin) {
        crossOriginReferrer = { referrerPolicy: 'no-referrer' };
      }
    }
  } catch {
    // keep defaults
  }

  return (
    <img
      src={src}
      alt={alt?.toString() || ''}
      width={typeof width === 'number' ? width : undefined}
      height={typeof height === 'number' ? height : undefined}
      className={className}
      style={style}
      {...crossOriginReferrer}
    />
  );
};

export default SafeImage;
