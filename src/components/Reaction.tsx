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
    <div
      className={clsx(
        isActive
          ? 'bg-green-50 border-green-500'
          : 'bg-transparent border-transparent',
        'h-5 w-5 rounded-full grid place-items-center border'
      )}
    >
      <Image className={'h-[92%] w-[92%]'} source={query.data?.metadata?.url} />
    </div>
  );
};

export default Reaction;
