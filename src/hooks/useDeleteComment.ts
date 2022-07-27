import { useMutation, useQueryClient } from 'react-query';
import { Comment } from '../api';
import useApi from './useApi';

interface UseDeleteCommentPayload {
  id: string;
}

const useDeleteComment = (comment: Comment) => {
  const queryClient = useQueryClient();
  const api = useApi();

  return useMutation(
    ({ id }: UseDeleteCommentPayload) => {
      return api.deleteComment(id);
    },
    {
      onMutate: ({ id }) => {
        queryClient.setQueryData<Comment[]>(
          ['comments', { topic: comment.topic, parentId: comment.parent_id }],
          (comments = []) => comments.filter((comment) => comment.id !== id)
        );
      },
      onSuccess: (data) => {
        queryClient.invalidateQueries([
          'comments',
          { topic: data.topic, parentId: data.parent_id },
        ]);
      },
    }
  );
};

export default useDeleteComment;
