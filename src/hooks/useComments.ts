import { useQuery, useQueryClient } from 'react-query';
import { timeout } from '../utils';
import useApi from './useApi';

interface UseCommentsQuery {
  topic: string;
  parentId: string | null;
}

interface UseCommentsOptions {
  enabled?: boolean;
}

const useComments = (
  { topic, parentId = null }: UseCommentsQuery,
  options: UseCommentsOptions = {}
) => {
  const api = useApi();
  const queryClient = useQueryClient();

  return useQuery(
    ['comments', { topic, parentId }],
    async () => {
      // This might look crazy, but it ensures the spinner will show for a
      // minimum of 200ms which is a pleasant amount of time for the sake of ux.
      const minTime = timeout(220);
      const comments = await api.getComments({ topic, parentId });
      await minTime;
      return comments;
    },
    {
      enabled: options.enabled,
      onSuccess: (data) => {
        data?.forEach((comment) => {
          queryClient.setQueryData(['comments', comment.id], comment);
          queryClient.setQueryData(['users', comment.user.id], comment.user);
        });
      },
    }
  );
};

export default useComments;
