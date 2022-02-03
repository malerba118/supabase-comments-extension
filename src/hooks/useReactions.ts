import { useQuery, useQueryClient } from 'react-query';
import useApi from './useApi';

interface UseReactionsOptions {
  enabled?: boolean;
}
const useReactions = (options: UseReactionsOptions = {}) => {
  const api = useApi();
  const queryClient = useQueryClient();

  return useQuery(
    ['reactions'],
    () => {
      return api.getReactions();
    },
    {
      enabled: options.enabled,
      staleTime: Infinity,
      onSuccess: (data) => {
        data?.forEach((reaction) => {
          queryClient.setQueryData(['reactions', reaction.type], reaction);
        });
      },
    }
  );
};

export default useReactions;
