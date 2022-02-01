import React, { FC } from 'react';
import type * as api from '../api';
import CommentReaction from './CommentReaction';
import ReactionSelector from './ReactionSelector';

export interface CommentReactionsProps {
  activeReactions: Set<string>;
  reactionsMetadata: api.CommentReactionMetadata[];
  toggleReaction: (reactionType: string) => void;
}

export const CommentReactions: FC<CommentReactionsProps> = ({
  activeReactions,
  reactionsMetadata,
  toggleReaction,
}) => {
  return (
    <div className="flex h-6 space-x-2">
      <ReactionSelector
        activeReactions={activeReactions}
        toggleReaction={toggleReaction}
      />
      {reactionsMetadata.map((reactionMetadata) => (
        <CommentReaction
          key={reactionMetadata.reaction_type}
          metadata={reactionMetadata}
          toggleReaction={toggleReaction}
        />
      ))}
    </div>
  );
};

export default CommentReactions;
