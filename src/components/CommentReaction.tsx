import React, { FC } from 'react';
import Reaction from './Reaction';
import { CommentReactionMetadata } from '../api';

interface CommentReactionProps {
  metadata: CommentReactionMetadata;
  toggleReaction: (reactionType: string) => void;
}

const CommentReaction: FC<CommentReactionProps> = ({
  metadata,
  toggleReaction,
}) => {
  return (
    <div className="flex space-x-2 p-0.5 bg-black bg-opacity-5 rounded-full items-center">
      <div
        tabIndex={0}
        className={'cursor-pointer'}
        onClick={() => {
          toggleReaction(metadata.reaction_type);
        }}
      >
        <Reaction
          isActive={metadata.active_for_user}
          type={metadata.reaction_type}
        />
      </div>
      <p className="text-xs pr-1.5">{metadata.reaction_count}</p>
    </div>
  );
};

export default CommentReaction;
