import React, { FC, useState } from 'react';
import { Loading, Modal, Typography } from '@supabase/ui';
import { useCommentReactions } from '../hooks';
import Avatar from './Avatar';
import Reaction from './Reaction';
import { CommentReactionMetadata } from '../api';
import clsx from 'clsx';
import User from './User';

const CommentReactionsModal = ({
  visible,
  commentId,
  reactionType,
  onClose,
}: any) => {
  const query = useCommentReactions(
    {
      commentId,
      reactionType,
    },
    { enabled: visible }
  );

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
        <div className="max-h-[320px] overflow-y-auto space-y-3 w-full">
          {query.isLoading && (
            <div className="grid w-full h-10 place-items-center">
              <div className="mr-4">
                <Loading active>{null}</Loading>
              </div>
            </div>
          )}
          {query.data?.map((commentReaction) => (
            <User
              key={commentReaction.id}
              id={commentReaction.user_id}
              showAvatar
              showName
              className="font-bold"
            />
          ))}
        </div>
      </Modal>
    </div>
  );
};

export interface CommentReactionProps {
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
          'flex space-x-2 py-0.5 px-1 rounded-full items-center border-2',
          metadata.active_for_user
            ? `bg-[color:var(--sce-accent-50)] dark:bg-[color:var(--sce-accent-900)] border-[color:var(--sce-accent-200)] dark:border-[color:var(--sce-accent-600)]`
            : 'bg-transparent border-alpha-10'
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
        <p className="pr-1 text-xs dark:text-[color:var(--sce-accent-50)] text-[color:var(--sce-accent-900)]">
          <span className="cursor-pointer" onClick={() => setShowDetails(true)}>
            {metadata.reaction_count}
          </span>
        </p>
      </div>
    </>
  );
};

export default CommentReaction;
