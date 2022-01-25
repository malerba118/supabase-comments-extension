import React, { FC, useState } from 'react';
import { Modal, Typography } from '@supabase/ui';
import { useCommentReactions } from '../hooks';
import Avatar from './Avatar';
import Reaction from './Reaction';
import { CommentReactionMetadata } from '../api';
import clsx from 'clsx';

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
      <div
        className={clsx(
          metadata.active_for_user
            ? 'bg-green-50 border-green-200'
            : 'bg-transparent border-black border-opacity-10',
          'flex space-x-2 p-0.5 rounded-full items-center border'
        )}
      >
        <div
          tabIndex={0}
          className={'cursor-pointer'}
          onClick={() => {
            toggleReaction(metadata.reaction_type);
          }}
        >
          <Reaction type={metadata.reaction_type} />
        </div>
        <p className="pr-1 text-xs">
          <span className="cursor-pointer" onClick={() => setShowDetails(true)}>
            {metadata.reaction_count}
          </span>
        </p>
      </div>
    </>
  );
};

export default CommentReaction;
