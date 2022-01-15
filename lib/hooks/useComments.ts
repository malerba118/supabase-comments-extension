import { useQuery, useQueryClient } from "react-query";
import * as api from "../api";

interface UseCommentsOptions {
  topic: string;
  parentId: string | null;
}

const useComments = ({ topic, parentId = null }: UseCommentsOptions) => {
  const queryClient = useQueryClient();
  return useQuery(
    ["comments", { topic, parentId }],
    () => {
      return api.getComments({ topic, parentId });
    },
    {
      onSuccess: (data) => {
        data?.forEach((comment) => {
          queryClient.setQueryData(["comments", comment.id], comment);
          comment.reactions_metadata.forEach((reactionMetadata) => {
            queryClient.setQueryData(
              [
                "comment-reactions-metadata",
                {
                  commentId: reactionMetadata.comment_id,
                  reactionType: reactionMetadata.reaction_type,
                },
              ],
              reactionMetadata
            );
          });
        });
      },
    }
  );
};

export default useComments;
