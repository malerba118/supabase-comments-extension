import { Dropdown, Typography } from '@supabase/ui';
import React, { FC } from 'react';
import useReactions from '../hooks/useReactions';
import Reaction from './Reaction';

interface ReactionSelectorProps {
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
            <div className="-ml-2">
              <Reaction
                isActive={activeReactions.has(reaction.type)}
                type={reaction.type}
              />
            </div>
          }
        >
          <Typography.Text>{reaction.metadata.label}</Typography.Text>
        </Dropdown.Item>
      ))}
    >
      <div className="flex space-x-1 p-0.5 bg-black bg-opacity-5 rounded-full">
        <div className="grid items-center justify-center w-5 h-5 text-xs bg-black rounded-full bg-opacity-5">
          <span>+</span>
        </div>
      </div>
    </Dropdown>
  );
};

export default ReactionSelector;
