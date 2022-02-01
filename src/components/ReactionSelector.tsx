import { Dropdown, IconPlus, Typography } from '@supabase/ui';
import clsx from 'clsx';
import React, { FC } from 'react';
import useReactions from '../hooks/useReactions';
import Reaction from './Reaction';

export interface ReactionSelectorProps {
  activeReactions: Set<string>;
  toggleReaction: (reactionType: string) => void;
}

const ReactionSelector: FC<ReactionSelectorProps> = ({
  activeReactions,
  toggleReaction,
}) => {
  const reactions = useReactions();
  return (
    <Dropdown
      overlay={reactions.data?.map((reaction) => (
        <Dropdown.Item
          key={reaction.type}
          onClick={() => {
            toggleReaction(reaction.type);
          }}
          icon={
            <div
              className={clsx(
                'p-0.5 -ml-2 border-2 rounded-full',
                activeReactions.has(reaction.type)
                  ? 'bg-[color:var(--sce-accent-50)] border-[color:var(--sce-accent-200)] dark:bg-[color:var(--sce-accent-900)] dark:border-[color:var(--sce-accent-600)]'
                  : 'bg-transparent border-transparent'
              )}
            >
              <Reaction type={reaction.type} />
            </div>
          }
        >
          <Typography.Text className="text-sm">
            {reaction.label}
          </Typography.Text>
        </Dropdown.Item>
      ))}
    >
      <div className="flex items-center justify-center w-[22px] h-[22px] text-xs rounded-full border-alpha-10 border-2">
        <IconPlus className="w-[12px] h-[12px] text-alpha-50" />
      </div>
    </Dropdown>
  );
};

export default ReactionSelector;
