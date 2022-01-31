import { useQuery, useQueryClient } from 'react-query';
import { timeout } from '../utils';
import useApi from './useApi';

interface UseCommentsOptions {
  topic: string;
  parentId: string | null;
}

const useComments = ({ topic, parentId = null }: UseCommentsOptions) => {
  const api = useApi();
  const queryClient = useQueryClient();

  return useQuery(
    ['comments', { topic, parentId }],
    async () => {
      // This might look crazy, but it ensures the spinner will show for a
      // minimum of 200ms which is a pleasant amount of time for the sake of ux.
      const minTime = timeout(200);
      const comments = await api.getComments({ topic, parentId });
      await minTime;
      return comments;
    },
    {
      onSuccess: (data) => {
        data?.forEach((comment) => {
          queryClient.setQueryData(['comments', comment.id], comment);
        });
      },
    }
  );
};

export default useComments;
