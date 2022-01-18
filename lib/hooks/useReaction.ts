import { useQuery } from "react-query";
import useApi from "./useApi";

const useReaction = (type: string) => {
  const api = useApi();

  return useQuery(
    ["reactions", type],
    () => {
      return api.getReaction(type);
    },
    {
      staleTime: Infinity,
    }
  );
};

export default useReaction;
