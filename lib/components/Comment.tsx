import { Badge, Image, Loading } from "@supabase/ui";
import { FC, useState } from "react";
import { Comments } from ".";
import { useComment } from "../hooks";
import useAddReaction from "../hooks/useAddReaction";
import useRemoveReaction from "../hooks/useRemoveReaction";
import CommentReaction from "./CommentReaction";
import ReactionSelector from "./ReactionSelector";

interface CommentProps {
  id: string;
}

const Comment: FC<CommentProps> = ({ id }) => {
  const [repliesVisible, setRepliesVisible] = useState(false);
  const query = useComment(id);
  const mutations = {
    addReaction: useAddReaction(),
    removeReaction: useRemoveReaction(),
  };

  const activeReactions = query.data?.reactions_metadata.reduce(
    (set, reactionMetadata) => {
      if (reactionMetadata.active_for_user) {
        set.add(reactionMetadata.reaction_type);
      }
      return set;
    },
    new Set<string>()
  );

  const toggleReaction = (reactionType: string) => {
    if (!activeReactions) {
      return;
    }
    if (!activeReactions.has(reactionType)) {
      mutations.addReaction.mutate({
        commentId: id,
        reactionType,
      });
    } else {
      mutations.removeReaction.mutate({
        commentId: id,
        reactionType,
      });
    }
  };

  return (
    <div className=" space-y-1">
      {query.isLoading && (
        <div className="h-12 grid place-items-center">
          <Loading active>{null}</Loading>
        </div>
      )}
      {query.data && activeReactions && (
        <div className="flex space-x-2">
          <div className="min-w-fit">
            <Image
              source={
                "https://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50"
              }
              className="rounded-full h-8 w-8"
            />
          </div>
          <div className="space-y-2 flex-1">
            <div className="bg-black bg-opacity-5 p-2 py-1 rounded-md">
              <p className="font-bold">{query.data.user.name}</p>
              <p>{query.data?.comment}</p>
            </div>
            <div className="flex justify-between items-center">
              <div className="flex space-x-2">
                <ReactionSelector
                  activeReactions={activeReactions}
                  toggleReaction={toggleReaction}
                />
                {query.data.reactions_metadata.map((reactionMetadata) => (
                  <CommentReaction
                    key={reactionMetadata.reaction_type}
                    metadata={reactionMetadata}
                    toggleReaction={toggleReaction}
                  />
                ))}
              </div>
              {query.data.replies_count > 0 && (
                <div
                  onClick={() => setRepliesVisible((prev) => !prev)}
                  className="text-sm text-gray-500 cursor-pointer"
                  tabIndex={0}
                >
                  {!repliesVisible && (
                    <p>view replies ({query.data.replies_count})</p>
                  )}
                  {repliesVisible && <p>hide replies</p>}
                </div>
              )}
            </div>
            <div>
              {repliesVisible && query.data.replies_count > 0 && (
                <Comments topic={query.data.topic} parentId={query.data.id} />
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Comment;
