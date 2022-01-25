import React, { FC } from 'react';
import { Image } from '@supabase/ui';
import { useReaction } from '../hooks';
import clsx from 'clsx';

interface ReactionProps {
  type: string;
  isActive?: boolean;
}

const Reaction: FC<ReactionProps> = ({ type, isActive }) => {
  const query = useReaction(type);

  return (
    <div className={clsx('h-4 w-4 rounded-full grid place-items-center')}>
      <Image className={'h-4 w-4'} source={query.data?.metadata?.url} />
    </div>
  );
};

export default Reaction;
