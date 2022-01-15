import { useQuery, useQueryClient } from "react-query";
import * as api from "../api";

interface UseCommentReactionMetadataParams {
  commentId: string;
  reactionType: string;
}

const useCommentReactionMetadata = ({
  commentId,
  reactionType,
}: UseCommentReactionMetadataParams) => {
  const queryClient = useQueryClient();

  return useQuery(
    [
      "comment-reactions-metadata",
      {
        commentId,
        reactionType,
      },
    ],
    () => {
      return api.getCommentReactionMetadata({
        commentId,
        reactionType,
      });
    },
    {
      staleTime: Infinity,
    }
  );
};

export default useCommentReactionMetadata;
