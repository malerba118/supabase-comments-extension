import React, { FC, useEffect, useLayoutEffect, useState } from 'react';
import { Loading, Button, Typography, IconAlertCircle } from '@supabase/ui';
import clsx from 'clsx';
import {
  useComments,
  useReactions,
  useAddComment,
  useUncontrolledState,
} from '../hooks';
import Editor from './Editor';
import Comment from './Comment';
import { useReplyManager } from './ReplyManagerProvider';
import { getMentionedUserIds } from '../utils';
import useAuthUtils from '../hooks/useAuthUtils';
import { useCommentsContext } from './CommentsProvider';
import Avatar from './Avatar';
import useUser from '../hooks/useUser';
import User from './User';

interface CommentsProps {
  topic: string;
  parentId?: string | null;
}

const Comments: FC<CommentsProps> = ({ topic, parentId = null }) => {
  const context = useCommentsContext();
  const [layoutReady, setLayoutReady] = useState(false);
  const replyManager = useReplyManager();
  const commentState = useUncontrolledState({ defaultValue: '' });
  const { auth, isAuthenticated, runIfAuthenticated } = useAuthUtils();

  const queries = {
    comments: useComments({ topic, parentId }),
    user: useUser({ id: auth.user?.id!, enabled: !!auth.user?.id }),
  };

  const mutations = {
    addComment: useAddComment(),
  };

  // preload reactions
  useReactions();

  useEffect(() => {
    if (replyManager?.replyingTo) {
      commentState.setDefaultValue(
        `<span data-type="mention" data-id="${replyManager?.replyingTo.user.id}" data-label="${replyManager?.replyingTo.user.name}" contenteditable="false"></span><span>&nbsp</span>`
      );
    } else {
      commentState.setDefaultValue('');
    }
  }, [replyManager?.replyingTo]);

  useEffect(() => {
    if (mutations.addComment.isSuccess) {
      replyManager?.setReplyingTo(null);
      commentState.setDefaultValue('');
    }
  }, [mutations.addComment.isSuccess]);

  useLayoutEffect(() => {
    if (queries.comments.isSuccess) {
      // this is neccessary because tiptap on first render has different height than on second render
      // which causes layout shift. this just hides content on the first render to avoid ugly layout
      // shift that happens when comment height changes.
      setLayoutReady(true);
    }
  }, [queries.comments.isSuccess]);

  const user = queries.user.data;

  return (
    <div className={clsx(context.mode, 'relative')}>
      {queries.comments.isLoading && (
        <div className="grid p-4 place-items-center">
          <div className="mr-4">
            <Loading active>{null}</Loading>
          </div>
        </div>
      )}
      {queries.comments.isError && (
        <div className="grid p-4 place-items-center">
          <div className="flex flex-col items-center space-y-0.5 text-center">
            <Typography.Text>
              <IconAlertCircle />
            </Typography.Text>
            <Typography.Text>Unable to load comments.</Typography.Text>
          </div>
        </div>
      )}
      {queries.comments.data && (
        <div
          className={clsx(
            'relative space-y-1 rounded-md',
            !layoutReady ? 'invisible' : 'visible'
          )}
        >
          <div className="space-y-1">
            {queries.comments.data.map((comment) => (
              <Comment key={comment.id} id={comment.id} />
            ))}
          </div>
          <div className="flex space-x-2">
            <div className="min-w-fit">
              <User id={user?.id} showAvatar showName={false} />
            </div>
            <div className="flex-1">
              <Editor
                key={commentState.key}
                defaultValue={commentState.defaultValue}
                onChange={(val) => {
                  commentState.setValue(val);
                }}
                autoFocus={!!replyManager?.replyingTo}
                actions={
                  <Button
                    onClick={() => {
                      runIfAuthenticated(() => {
                        mutations.addComment.mutate({
                          topic,
                          parentId,
                          comment: commentState.value,
                          mentionedUserIds: getMentionedUserIds(
                            commentState.value
                          ),
                        });
                      });
                    }}
                    loading={mutations.addComment.isLoading}
                    loadingCentered
                    size="tiny"
                    className="!px-[6px] !py-[3px] m-[3px]"
                  >
                    {!isAuthenticated ? 'Sign In' : 'Submit'}
                  </Button>
                }
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Comments;
