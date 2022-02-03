import { useQuery } from 'react-query';
import useApi from './useApi';

interface UseCommentQuery {
  id: string;
}

interface UseCommentOptions {
  enabled?: boolean;
}

const useComment = (
  { id }: UseCommentQuery,
  options: UseCommentOptions = {}
) => {
  const api = useApi();

  return useQuery(
    ['comments', id],
    () => {
      return api.getComment(id);
    },
    {
      staleTime: Infinity,
      enabled: options.enabled,
    }
  );
};

export default useComment;
