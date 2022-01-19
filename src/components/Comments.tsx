import React, { FC, useEffect, useState } from 'react';
import { useComments } from '../hooks';
import Comment from './Comment';
import { Loading, Button } from '@supabase/ui';
import useReactions from '../hooks/useReactions';
import useAddComment from '../hooks/useAddComment';
import Editor from './Editor';
import useUncontrolledState from '../hooks/useUncontrolledState';

interface CommentsProps {
  topic: string;
  parentId?: string | null;
  autoFocusInput?: boolean;
}

const Comments: FC<CommentsProps> = ({
  topic,
  parentId = null,
  autoFocusInput = false,
}) => {
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
    if (mutations.addComment.isSuccess) {
      commentState.setDefaultValue('');
    }
  }, [mutations.addComment.isSuccess]);

  if (queries.comments.isLoading) {
    return (
      <div className="grid h-12 place-items-center">
        <Loading active>{null}</Loading>
      </div>
    );
  }

  return (
    <div className="space-y-3 rounded-md">
      <div className="space-y-1">
        {queries.comments.data?.map((comment) => (
          <Comment key={comment.id} id={comment.id} />
        ))}
      </div>
      <div className="ml-10 space-y-2">
        {/* <Input.TextArea
          autofocus={autoFocusInput}
          placeholder="Comment..."
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
        /> */}
        <Editor
          key={commentState.key}
          defaultValue={commentState.defaultValue}
          onChange={(val) => {
            commentState.setValue(val);
          }}
          autoFocus={autoFocusInput}
        />
        <Button
          onClick={() => {
            mutations.addComment.mutate({
              topic,
              parentId,
              comment: commentState.value,
            });
          }}
        >
          Submit
        </Button>
      </div>
    </div>
  );
};

export default Comments;
