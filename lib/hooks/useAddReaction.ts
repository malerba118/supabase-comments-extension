import { useMutation, useQueryClient } from "react-query";
import * as api from "../api";

interface UseAddReactionPayload {
  reactionType: string;
  commentId: string;
}

const useAddReaction = () => {
  const queryClient = useQueryClient();

  return useMutation(
    (payload: UseAddReactionPayload) => {
      return api.addCommentReaction({
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

export default useAddReaction;
