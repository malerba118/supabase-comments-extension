import { useQuery, useQueryClient } from 'react-query';
import useApi from './useApi';

interface UseSearchUsersQuery {
  search: string;
}

interface UseSearchUsersOptions {
  enabled?: boolean;
}

const useSearchUsers = (
  { search }: UseSearchUsersQuery,
  options: UseSearchUsersOptions = {}
) => {
  const api = useApi();
  const queryClient = useQueryClient();

  return useQuery(
    ['users', { search }],
    () => {
      return api.searchUsers(search);
    },
    {
      enabled: options.enabled,
      staleTime: Infinity,
      onSuccess: (data) => {
        data?.forEach((user) => {
          queryClient.setQueryData(['users', user.id], user);
        });
      },
    }
  );
};

export default useSearchUsers;
