import { useQuery, useQueryClient } from "react-query";
import useApi from "./useApi";

const useComment = (id: string) => {
  const api = useApi();
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
