import { FC } from "react";
import { useComment } from "../hooks";

interface CommentProps {
  id: string;
}

const Comment: FC<CommentProps> = ({ id }) => {
  const query = useComment(id);
  return <div>{query.data?.comment}</div>;
};

export default Comment;
