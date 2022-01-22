import { useQuery } from 'react-query';
import useApi from './useApi';

interface UseCommentReactionsOptions {
  commentId: string;
  reactionType: string;
  enabled?: boolean;
}

const useCommentReactions = ({
  commentId,
  reactionType,
  enabled = true,
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
      enabled,
    }
  );
};

export default useCommentReactions;
