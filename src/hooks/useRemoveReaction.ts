import { useMutation, useQueryClient } from 'react-query';
import { Comment } from '../api';
import useApi from './useApi';

interface UseRemoveReactionPayload {
  reactionType: string;
  commentId: string;
}

// Do a little surgery on the comment and manually decrement the reaction count
// or remove the item from the array if the reaction count was only 1
const removeOrDecrement = (reactionType: string, comment: Comment): Comment => {
  let newArray = [...comment.reactions_metadata];
  newArray = newArray.map((item) => {
    if (item.reaction_type === reactionType) {
      return {
        ...item,
        reaction_count: item.reaction_count - 1,
        active_for_user: false,
      };
    } else {
      return item;
    }
  });
  newArray = newArray.filter((item) => {
    return item.reaction_count > 0;
  });
  newArray.sort((a, b) => a.reaction_type.localeCompare(b.reaction_type));
  return {
    ...comment,
    reactions_metadata: newArray,
  };
};

const useRemoveReaction = () => {
  const api = useApi();
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
        // Manually patch the comment while it refetches
        queryClient.setQueryData(
          ['comments', params.commentId],
          (prev: Comment) => removeOrDecrement(params.reactionType, prev)
        );
        queryClient.invalidateQueries(['comments', params.commentId]);
        queryClient.invalidateQueries([
          'comment-reactions',
          { commentId: params.commentId, reactionType: params.reactionType },
        ]);
      },
    }
  );
};

export default useRemoveReaction;
