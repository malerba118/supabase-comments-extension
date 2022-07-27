import { useMutation, useQueryClient } from 'react-query';
import { Comment, CommentReaction } from '../api';
import { useSupabaseClient } from '../components/CommentsProvider';
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
  const supabaseClient = useSupabaseClient();

  return useMutation(
    (payload: UseRemoveReactionPayload) => {
      return api.removeCommentReaction({
        reaction_type: payload.reactionType,
        comment_id: payload.commentId,
      });
    },
    {
      onMutate: (payload) => {
        // Manually patch the comment while it refetches
        queryClient.setQueryData(
          ['comments', payload.commentId],
          (prev: Comment) => removeOrDecrement(payload.reactionType, prev)
        );

        queryClient.setQueryData<CommentReaction[]>(
          [
            'comment-reactions',
            {
              commentId: payload.commentId,
              reactionType: payload.reactionType,
            },
          ],
          (reactions) => {
            if (!reactions?.length) return [];

            const user = supabaseClient.auth.user();

            if (!user) return reactions;

            return reactions.filter(
              (reaction) =>
                reaction.user_id !== user.id &&
                reaction.reaction_type !== payload.reactionType
            );
          }
        );
      },
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

export default useRemoveReaction;
