import { Badge, Image, Loading } from "@supabase/ui";
import { FC, useState } from "react";
import { Comments } from ".";
import { useComment } from "../hooks";
import CommentReaction from "./CommentReaction";

interface CommentProps {
  id: string;
}

const Comment: FC<CommentProps> = ({ id }) => {
  const [repliesVisible, setRepliesVisible] = useState(false);
  const query = useComment(id);

  return (
    <div className=" space-y-1">
      {query.isLoading && (
        <div className="h-12 grid place-items-center">
          <Loading active>{null}</Loading>
        </div>
      )}
      {query.data && (
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
                <div className="flex space-x-1 p-1 bg-black bg-opacity-5 rounded-full">
                  <div className="h-4 w-4 rounded-full bg-black bg-opacity-5 text-xs grid items-center justify-center">
                    <span>+</span>
                  </div>
                </div>
                {query.data?.reactions_metadata.map((reactionMetadata) => (
                  <CommentReaction
                    key={reactionMetadata.reaction_type}
                    commentId={reactionMetadata.comment_id}
                    reactionType={reactionMetadata.reaction_type}
                  />
                ))}
              </div>
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
            </div>
            <div>
              {repliesVisible && query.data && query.data.replies_count > 0 && (
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
