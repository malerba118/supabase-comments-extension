import { useMutation, useQueryClient } from 'react-query';
import useApi from './useApi';

interface UseUpdateCommentPayload {
  id: string;
  comment: string;
  mentionedUserIds: string[];
}

const useUpdateComment = () => {
  const api = useApi();
  const queryClient = useQueryClient();

  return useMutation(
    ({ id, comment, mentionedUserIds }: UseUpdateCommentPayload) => {
      return api.updateComment(id, {
        comment,
        mentioned_user_ids: mentionedUserIds,
      });
    },
    {
      onSuccess: (data) => {
        queryClient.invalidateQueries(['comments', data.id]);
      },
    }
  );
};

export default useUpdateComment;
