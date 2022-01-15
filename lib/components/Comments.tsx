import { FC, useState } from "react";
import { useComments } from "../hooks";
import Comment from "./Comment";
import { Loading, Input, Button } from "@supabase/ui";
import { useMutation } from "react-query";
import useReactions from "../hooks/useReactions";

interface CommentsProps {
  topic: string;
  parentId?: string | null;
}

const Comments: FC<CommentsProps> = ({ topic, parentId = null }) => {
  const [draft, setDraft] = useState("");
  const queries = {
    comments: useComments({ topic, parentId }),
  };

  const mutations = {
    addComment: useMutation(async () => {}),
  };

  useReactions();

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
        <Input.TextArea
          placeholder="Comment..."
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
        />
        <Button>Submit</Button>
      </div>
    </div>
  );
};

export default Comments;
