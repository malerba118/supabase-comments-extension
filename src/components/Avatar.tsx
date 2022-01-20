import { Image } from '@supabase/ui';
import clsx from 'clsx';
import React, { FC } from 'react';
import { useImage } from 'react-image';

interface AvatarProps extends React.HTMLProps<HTMLDivElement> {
  src: string;
}

const Avatar: FC<AvatarProps> = ({ src, className, ...otherProps }) => {
  const image = useImage({ srcList: src, useSuspense: false });

  return (
    <div
      {...otherProps}
      className={clsx(
        'relative inline-block w-8 h-8 overflow-hidden rounded-full bg-black bg-opacity-10 dark:bg-white dark:bg-opacity-10',
        className
      )}
    >
      {image.src && (
        <Image
          className="object-cover w-full h-full rounded-full"
          source={image.src}
        />
      )}

      {image.isLoading && <div className="absolute inset-0"></div>}
      {image.error && <div className="absolute inset-0"></div>}
    </div>
  );
};

export default Avatar;
