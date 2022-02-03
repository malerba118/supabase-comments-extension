import { useQuery } from 'react-query';
import useApi from './useApi';

interface UseCommentReactionsQuery {
  commentId: string;
  reactionType: string;
}

interface UseCommentReactionsOptions {
  enabled?: boolean;
}

const useCommentReactions = (
  { commentId, reactionType }: UseCommentReactionsQuery,
  options: UseCommentReactionsOptions = {}
) => {
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
      enabled: options.enabled,
    }
  );
};

export default useCommentReactions;
