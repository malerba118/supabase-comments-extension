import { useMutation, useQueryClient } from 'react-query';
import { Comment } from '../api';
import { useSupabaseClient } from '../components/CommentsProvider';
import { randomString } from '../utils';
import useApi from './useApi';

interface UseAddCommentPayload {
  comment: string;
  topic: string;
  parentId: string | null;
  mentionedUserIds: string[];
}

const useAddComment = () => {
  const queryClient = useQueryClient();
  const api = useApi();
  const supabaseClient = useSupabaseClient();

  return useMutation(
    ({ comment, topic, parentId, mentionedUserIds }: UseAddCommentPayload) => {
      return api.addComment({
        comment,
        topic,
        parent_id: parentId,
        mentioned_user_ids: mentionedUserIds,
      });
    },
    {
      onMutate: (payload) => {
        queryClient.setQueryData<Comment[]>(
          ['comments', { topic: payload.topic, parentId: payload.parentId }],
          (comments = []) => {
            const user = supabaseClient.auth.user();

            if (!user) return comments;

            const userMetadata = user.user_metadata;

            const name =
              userMetadata.name ||
              userMetadata.full_name ||
              userMetadata.user_name;
            const avatar = userMetadata.avatar || userMetadata.avatar_url;

            comments.push({
              comment: payload.comment,
              topic: payload.topic,
              parent_id: payload.parentId,
              user_id: user?.id,
              mentioned_user_ids: payload.mentionedUserIds,
              created_at: new Date().toUTCString(),
              // Fake id, use random string to make sure the comment is unique
              id: randomString(),
              replies_count: 0,
              user: {
                avatar,
                name,
                id: user.id,
              },
              reactions_metadata: [],
            });

            return comments;
          }
        );
      },
      onSuccess: (data, params) => {
        queryClient.invalidateQueries([
          'comments',
          { topic: params.topic, parentId: params.parentId },
        ]);
      },
    }
  );
};

export default useAddComment;
