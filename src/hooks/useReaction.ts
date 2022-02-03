import { useQuery } from 'react-query';
import useApi from './useApi';

interface UseReactionQuery {
  type: string;
}

interface UseReactionOptions {
  enabled?: boolean;
}

const useReaction = (
  { type }: UseReactionQuery,
  options: UseReactionOptions = {}
) => {
  const api = useApi();

  return useQuery(
    ['reactions', type],
    () => {
      return api.getReaction(type);
    },
    {
      enabled: options.enabled,
      staleTime: Infinity,
    }
  );
};

export default useReaction;
