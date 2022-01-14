import { FC } from "react";
import { useComments } from "../hooks";
import Comment from "./Comment";

interface CommentsProps {
  topic: string;
}

const Comments: FC<CommentsProps> = ({ topic }) => {
  const queries = {
    comments: useComments({ topic }),
  };
  if (queries.comments.isLoading) {
    return <div>loading</div>;
  }

  return (
    <div>
      {queries.comments.data?.map((comment) => (
        <Comment id={comment.id} />
      ))}
    </div>
  );
};

export default Comments;
