import { useQuery } from "react-query";
import * as api from "../api";

const useReaction = (type: string) => {
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
