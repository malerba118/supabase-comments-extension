import { useQuery, useQueryClient } from 'react-query';
import useApi from './useApi';

const useComment = (id: string) => {
  const api = useApi();

  return useQuery(
    ['comments', id],
    () => {
      return api.getComment(id);
    },
    {
      staleTime: Infinity,
    }
  );
};

export default useComment;
