import { FC, useEffect, useState } from "react";
import { useComments } from "../hooks";
import Comment from "./Comment";
import { Loading, Input, Button } from "@supabase/ui";
import { useMutation } from "react-query";
import useReactions from "../hooks/useReactions";
import useAddComment from "../hooks/useAddComment";
import Editor from "./Editor";

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
  const [draft, setDraft] = useState("");
  const queries = {
    comments: useComments({ topic, parentId }),
  };

  const mutations = {
    addComment: useAddComment(),
  };
  useReactions();

  useEffect(() => {
    if (mutations.addComment.isSuccess) {
      setDraft("");
    }
  }, [mutations.addComment.isSuccess]);

  if (queries.comments.isLoading) {
    return (
      <div className="h-12 grid place-items-center">
        <Loading active>{null}</Loading>
      </div>
    );
  }

  return (
    <div className="space-y-3  rounded-md">
      <div className="space-y-1">
        {queries.comments.data?.map((comment) => (
          <Comment key={comment.id} id={comment.id} />
        ))}
      </div>
      <div className="space-y-2">
        {/* <Input.TextArea
          autofocus={autoFocusInput}
          placeholder="Comment..."
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
        /> */}
        <Editor
          defaultValue={draft}
          onChange={(val) => setDraft(val)}
          autoFocus={autoFocusInput}
        />
        <Button
          onClick={() => {
            mutations.addComment.mutate({
              topic,
              parentId,
              comment: draft,
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
