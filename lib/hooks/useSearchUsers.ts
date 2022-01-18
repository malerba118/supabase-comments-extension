import { useQuery, useQueryClient } from "react-query";
import useApi from "./useApi";

const useSearchUsers = (search: string) => {
  const api = useApi();
  const queryClient = useQueryClient();

  return useQuery(
    ["users", { search }],
    () => {
      return api.searchUsers(search);
    },
    {
      staleTime: Infinity,
      onSuccess: (data) => {
        data?.forEach((user) => {
          queryClient.setQueryData(["users", user.id], user);
        });
      },
    }
  );
};

export default useSearchUsers;
