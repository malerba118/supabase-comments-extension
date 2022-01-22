import React, { FC, useState } from 'react';
import { Modal, Typography } from '@supabase/ui';
import { useCommentReactions } from '../hooks';
import Avatar from './Avatar';
import Reaction from './Reaction';
import { CommentReactionMetadata } from '../api';

const CommentReactionsModal = ({
  visible,
  commentId,
  reactionType,
  onClose,
}: any) => {
  const query = useCommentReactions({
    commentId,
    reactionType,
    enabled: visible,
  });

  return (
    <div className="fixed inset-0 -z-10">
      <Modal
        title="Reactions"
        visible={visible}
        onCancel={() => onClose()}
        onConfirm={() => onClose()}
        showIcon={false}
        size="tiny"
        hideFooter
      >
        {query.data?.map((commentReaction) => (
          <div key={commentReaction.id} className="flex items-center space-x-2">
            <Avatar src={commentReaction.user.avatar} />
            <Typography.Text>{commentReaction.user.name}</Typography.Text>
          </div>
        ))}
      </Modal>
    </div>
  );
};

interface CommentReactionProps {
  metadata: CommentReactionMetadata;
  toggleReaction: (reactionType: string) => void;
}

const CommentReaction: FC<CommentReactionProps> = ({
  metadata,
  toggleReaction,
}) => {
  const [showDetails, setShowDetails] = useState(false);

  return (
    <>
      <CommentReactionsModal
        commentId={metadata.comment_id}
        reactionType={metadata.reaction_type}
        visible={showDetails}
        onClose={() => setShowDetails(false)}
        size="small"
      />
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
        <p className="text-xs pr-1.5">
          <span className="cursor-pointer" onClick={() => setShowDetails(true)}>
            {metadata.reaction_count}
          </span>
        </p>
      </div>
    </>
  );
};

export default CommentReaction;
