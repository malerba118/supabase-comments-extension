import { useMutation, useQueryClient } from 'react-query';
import useApi from './useApi';

interface UseAddReactionPayload {
  reactionType: string;
  commentId: string;
}

const useAddReaction = () => {
  const api = useApi();
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
        queryClient.invalidateQueries(['comments', params.commentId]);
        queryClient.invalidateQueries([
          'comment-reactions',
          { commentId: params.commentId, reactionType: params.reactionType },
        ]);
      },
    }
  );
};

export default useAddReaction;
