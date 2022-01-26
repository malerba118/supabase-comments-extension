import {
  Loading,
  Dropdown,
  Typography,
  IconMoreVertical,
  Button,
  Auth,
} from '@supabase/ui';
import React, { FC, useEffect, useState } from 'react';
import type * as api from '../api';
import {
  useComment,
  useDeleteComment,
  useUpdateComment,
  useAddReaction,
  useRemoveReaction,
  useUncontrolledState,
} from '../hooks';
import Avatar from './Avatar';
import Editor from './Editor';
import TimeAgo from './TimeAgo';
import Comments from './Comments';
import CommentReaction from './CommentReaction';
import ReactionSelector from './ReactionSelector';
import ReplyManagerProvider, { useReplyManager } from './ReplyManagerProvider';
import { useCommentsContext } from './CommentsProvider';
import { getMentionedUserIds } from '../utils';
import useAuthUtils from '../hooks/useAuthUtils';

interface CommentMenuProps {
  onEdit: () => void;
  onDelete: () => void;
}

const CommentMenu: FC<CommentMenuProps> = ({ onEdit, onDelete }) => {
  return (
    <Dropdown
      overlay={[
        <Dropdown.Item onClick={() => onEdit()}>
          <Typography.Text>Edit</Typography.Text>
        </Dropdown.Item>,
        <Dropdown.Item onClick={() => onDelete()}>
          <Typography.Text>Delete</Typography.Text>
        </Dropdown.Item>,
      ]}
    >
      <IconMoreVertical className="h-6 px-0.5 py-1.5" />
    </Dropdown>
  );
};

interface CommentProps {
  id: string;
}

const Comment: FC<CommentProps> = ({ id }) => {
  const query = useComment(id);

  return (
    <div className="space-y-1">
      {query.isLoading && (
        <div className="grid h-12 place-items-center">
          <Loading active>{null}</Loading>
        </div>
      )}
      {query.data && !query.data.parent_id && (
        <ReplyManagerProvider>
          <CommentData comment={query.data} />
        </ReplyManagerProvider>
      )}
      {query.data && query.data.parent_id && (
        <CommentData comment={query.data} />
      )}
    </div>
  );
};

interface CommentDataProps {
  comment: api.Comment;
}

const CommentData: FC<CommentDataProps> = ({ comment }) => {
  const context = useCommentsContext();
  const [editing, setEditing] = useState(false);
  const [repliesVisible, setRepliesVisible] = useState(false);
  const commentState = useUncontrolledState({ defaultValue: comment.comment });
  const replyManager = useReplyManager();
  const mutations = {
    addReaction: useAddReaction(),
    removeReaction: useRemoveReaction(),
    updateComment: useUpdateComment(),
    deleteComment: useDeleteComment(),
  };
  const { isAuthenticated, runIfAuthenticated, auth } = useAuthUtils();

  const isReplyingTo = replyManager?.replyingTo?.id === comment.id;

  useEffect(() => {
    if (comment.parent_id) {
      return;
    }
    // if we're at the top level use replyingTo
    // to control expansion state
    if (replyManager?.replyingTo) {
      setRepliesVisible(true);
    } else {
      // setRepliesVisible(false);
    }
  }, [replyManager?.replyingTo, comment.parent_id]);

  useEffect(() => {
    if (mutations.updateComment.isSuccess) {
      setEditing(false);
    }
  }, [mutations.updateComment.isSuccess]);

  const isReply = !!comment.parent_id;

  const activeReactions = comment.reactions_metadata.reduce(
    (set, reactionMetadata) => {
      if (reactionMetadata.active_for_user) {
        set.add(reactionMetadata.reaction_type);
      }
      return set;
    },
    new Set<string>()
  );

  const toggleReaction = (reactionType: string) => {
    runIfAuthenticated(() => {
      if (!activeReactions.has(reactionType)) {
        mutations.addReaction.mutate({
          commentId: comment.id,
          reactionType,
        });
      } else {
        mutations.removeReaction.mutate({
          commentId: comment.id,
          reactionType,
        });
      }
    });
  };

  return (
    <div className="flex space-x-2">
      <div className="min-w-fit">
        <Avatar
          className={'cursor-pointer'}
          onClick={() => {
            context.onUserClick?.(comment.user);
          }}
          src={comment.user.avatar}
        />
      </div>
      <div className="flex-1 space-y-2">
        <div className="relative p-2 py-1 text-black bg-black rounded-md text-opacity-90 bg-opacity-5 dark:text-white dark:text-opacity-90 dark:bg-white dark:bg-opacity-5">
          <div className="absolute top-0 right-0">
            {comment.user_id === auth?.user?.id && (
              <CommentMenu
                onEdit={() => {
                  setEditing(true);
                }}
                onDelete={() => {
                  mutations.deleteComment.mutate({ id: comment.id });
                }}
              />
            )}
          </div>
          <p>
            <span
              className="font-bold cursor-pointer"
              onClick={() => {
                context.onUserClick?.(comment.user);
              }}
            >
              {comment.user.name}
            </span>
          </p>
          <p>
            {!editing && (
              <Editor
                key={comment.comment}
                defaultValue={comment.comment}
                readOnly
              />
            )}
            {editing && (
              <Editor
                key={commentState.key}
                defaultValue={commentState.defaultValue}
                onChange={(val) => {
                  commentState.setValue(val);
                }}
                autoFocus={!!replyManager?.replyingTo}
                actions={
                  <div className="flex mx-[3px] space-x-[3px]">
                    <Button
                      onClick={() => {
                        setEditing(false);
                      }}
                      size="tiny"
                      className="!px-[6px] !py-[3px]"
                      type="secondary"
                    >
                      Cancel
                    </Button>
                    <Button
                      onClick={() => {
                        mutations.updateComment.mutate({
                          id: comment.id,
                          comment: commentState.value,
                          mentionedUserIds: getMentionedUserIds(
                            commentState.value
                          ),
                        });
                      }}
                      loading={mutations.updateComment.isLoading}
                      size="tiny"
                      className="!px-[6px] !py-[3px]"
                    >
                      Save
                    </Button>
                  </div>
                }
              />
            )}
          </p>
          <p className="text-sm text-gray-500">
            <TimeAgo date={comment.created_at} locale="en-US" />
          </p>
        </div>
        <div className="flex items-center justify-between">
          <div className="flex space-x-2">
            <ReactionSelector
              activeReactions={activeReactions}
              toggleReaction={toggleReaction}
            />
            {comment.reactions_metadata.map((reactionMetadata) => (
              <CommentReaction
                key={reactionMetadata.reaction_type}
                metadata={reactionMetadata}
                toggleReaction={toggleReaction}
              />
            ))}
          </div>
          <div className="flex space-x-3 text-sm text-gray-500 ">
            {!isReply && (
              <div
                onClick={() => setRepliesVisible((prev) => !prev)}
                className="cursor-pointer"
                tabIndex={0}
              >
                {!repliesVisible && (
                  <p>view replies ({comment.replies_count})</p>
                )}
                {repliesVisible && <p>hide replies</p>}
              </div>
            )}
            {!isReplyingTo && (
              <p
                tabIndex={0}
                className="cursor-pointer"
                onClick={() => {
                  replyManager?.setReplyingTo(comment);
                }}
              >
                reply
              </p>
            )}
            {isReplyingTo && (
              <p
                tabIndex={0}
                className="cursor-pointer"
                onClick={() => {
                  replyManager?.setReplyingTo(null);
                }}
              >
                cancel
              </p>
            )}
          </div>
        </div>
        <div>
          {repliesVisible && !isReply && (
            <div className="my-3">
              <Comments topic={comment.topic} parentId={comment.id} />
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Comment;
