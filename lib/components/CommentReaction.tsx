import { FC } from "react";
import { useComment, useCommentReactionMetadata } from "../hooks";
import { Badge } from "@supabase/ui";
import Reaction from "./Reaction";
import useAddReaction from "../hooks/useAddReaction";
import clsx from "clsx";

interface CommentReactionProps {
  commentId: string;
  reactionType: string;
}

const CommentReaction: FC<CommentReactionProps> = ({
  commentId,
  reactionType,
}) => {
  const query = useCommentReactionMetadata({ commentId, reactionType });
  const mutations = {
    addReaction: useAddReaction(),
  };
  return (
    <div className="flex space-x-2 p-1 bg-black bg-opacity-5 rounded-full">
      <div
        tabIndex={0}
        className={clsx(
          query.data?.active_for_user
            ? "bg-green-400"
            : "bg-black bg-opacity-5",
          "h-4 w-4 rounded-full cursor-pointer"
        )}
        onClick={() => {
          if (!query.data?.active_for_user) {
            mutations.addReaction.mutate({ commentId, reactionType });
          }
        }}
      >
        {query.data?.reaction_type && (
          <Reaction type={query.data?.reaction_type} />
        )}
      </div>
      <p className="text-xs pr-1">{query.data?.reaction_count || ""}</p>
    </div>
  );
};

export default CommentReaction;
