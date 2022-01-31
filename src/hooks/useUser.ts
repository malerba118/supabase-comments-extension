import { useQuery } from 'react-query';
import useApi from './useApi';

interface UseUserOptions {
  id: string;
  enabled?: boolean;
}

const useUser = ({ id, enabled = true }: UseUserOptions) => {
  const api = useApi();

  return useQuery(
    ['users', id],
    () => {
      return api.getUser(id);
    },
    {
      staleTime: Infinity,
      enabled,
    }
  );
};

export default useUser;
