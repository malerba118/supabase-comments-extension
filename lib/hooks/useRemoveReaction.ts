import { useMutation, useQueryClient } from "react-query";
import * as api from "../api";

interface UseRemoveReactionPayload {
  reactionType: string;
  commentId: string;
}

const useRemoveReaction = () => {
  const queryClient = useQueryClient();

  return useMutation(
    (payload: UseRemoveReactionPayload) => {
      return api.removeCommentReaction({
        reaction_type: payload.reactionType,
        comment_id: payload.commentId,
      });
    },
    {
      onSuccess: (data, params) => {
        queryClient.invalidateQueries(["comments", params.commentId]);
      },
    }
  );
};

export default useRemoveReaction;
