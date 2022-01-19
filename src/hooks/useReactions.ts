import { useQuery, useQueryClient } from "react-query";
import useApi from "./useApi";

const useReactions = () => {
  const api = useApi();
  const queryClient = useQueryClient();

  return useQuery(
    ["reactions"],
    () => {
      return api.getReactions();
    },
    {
      staleTime: Infinity,
      onSuccess: (data) => {
        data?.forEach((reaction) => {
          queryClient.setQueryData(["reactions", reaction.type], reaction);
        });
      },
    }
  );
};

export default useReactions;
