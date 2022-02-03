import { useQuery } from 'react-query';
import useApi from './useApi';

interface UseUserQuery {
  id: string;
}

interface UseUserOptions {
  enabled?: boolean;
}

const useUser = ({ id }: UseUserQuery, options: UseUserOptions = {}) => {
  const api = useApi();

  return useQuery(
    ['users', id],
    () => {
      return api.getUser(id);
    },
    {
      staleTime: Infinity,
      enabled: options.enabled,
    }
  );
};

export default useUser;
