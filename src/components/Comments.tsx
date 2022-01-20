import React, { FC, useEffect, useLayoutEffect, useState } from 'react';
import { useComments } from '../hooks';
import Comment from './Comment';
import { Loading, Button } from '@supabase/ui';
import useReactions from '../hooks/useReactions';
import useAddComment from '../hooks/useAddComment';
import Editor from './Editor';
import useUncontrolledState from '../hooks/useUncontrolledState';
import { useReplyManager } from './ReplyManagerProvider';
import clsx from 'clsx';
import { getMentionedUserIds } from '../utils';

interface CommentsProps {
  topic: string;
  parentId?: string | null;
}

const Comments: FC<CommentsProps> = ({ topic, parentId = null }) => {
  const [layoutReady, setLayoutReady] = useState(false);
  const replyManager = useReplyManager();
  const commentState = useUncontrolledState({ defaultValue: '' });
  const queries = {
    comments: useComments({ topic, parentId }),
  };

  const mutations = {
    addComment: useAddComment(),
  };

  // preload reactions
  useReactions();

  useEffect(() => {
    if (replyManager?.replyingTo) {
      commentState.setDefaultValue(
        `<span data-type="mention" data-id="${replyManager?.replyingTo.user.id}" data-label="${replyManager?.replyingTo.user.name}" contenteditable="false"></span>`
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

  if (queries.comments.isLoading) {
    return (
      <div className="grid h-12 place-items-center">
        <Loading active>{null}</Loading>
      </div>
    );
  }

  return (
    <div
      className={clsx(
        'space-y-3 rounded-md',
        !layoutReady ? 'invisible' : 'visible'
      )}
    >
      <div className="space-y-1">
        {queries.comments.data?.map((comment) => (
          <Comment key={comment.id} id={comment.id} />
        ))}
      </div>
      <div className="ml-10 space-y-2">
        <Editor
          key={commentState.key}
          defaultValue={commentState.defaultValue}
          onChange={(val) => {
            commentState.setValue(val);
          }}
          autoFocus={!!replyManager?.replyingTo}
        />
        <Button
          onClick={() => {
            mutations.addComment.mutate({
              topic,
              parentId,
              comment: commentState.value,
              mentionedUserIds: getMentionedUserIds(commentState.value),
            });
          }}
          loading={mutations.addComment.isLoading}
        >
          Submit
        </Button>
      </div>
    </div>
  );
};

export default Comments;
