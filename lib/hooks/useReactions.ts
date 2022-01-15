import { useQuery, useQueryClient } from "react-query";
import * as api from "../api";

const useReactions = () => {
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
