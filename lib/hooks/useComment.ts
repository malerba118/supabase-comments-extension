import { useQuery, useQueryClient } from "react-query";
import * as api from "../api";

const useComment = (id: string) => {
  const queryClient = useQueryClient();

  return useQuery(
    ["comments", id],
    () => {
      return api.getComment(id);
    },
    {
      staleTime: Infinity,
      onSuccess: (data) => {
        data.reactions_metadata.forEach((reactionMetadata) => {
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
      },
    }
  );
};

export default useComment;
