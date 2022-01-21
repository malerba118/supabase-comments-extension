import { useQuery, useQueryClient } from 'react-query';
import useApi from './useApi';

interface UseCommentReactionsOptions {
  commentId: string;
  reactionType: string;
}

const useCommentReactions = ({
  commentId,
  reactionType,
}: UseCommentReactionsOptions) => {
  const api = useApi();

  return useQuery(
    ['comment-reactions', { commentId, reactionType }],
    () => {
      return api.getCommentReactions({
        comment_id: commentId,
        reaction_type: reactionType,
      });
    },
    {
      staleTime: Infinity,
    }
  );
};

export default useCommentReactions;
