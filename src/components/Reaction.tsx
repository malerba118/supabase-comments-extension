import React, { FC } from 'react';
import { Image } from '@supabase/ui';
import { useReaction } from '../hooks';
import clsx from 'clsx';

interface ReactionProps {
  type: string;
}

const Reaction: FC<ReactionProps> = ({ type }) => {
  const query = useReaction(type);

  return (
    <div
      className={clsx(
        'h-4 w-4 rounded-full grid place-items-center dark:text-white'
      )}
    >
      <Image className={'h-4 w-4'} source={query.data?.metadata?.url} />
    </div>
  );
};

export default Reaction;
