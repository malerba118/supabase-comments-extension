import { useQuery, useQueryClient } from "react-query";
import * as api from "../api";

const useComment = (id: string) => {
  return useQuery(
    ["comments", id],
    () => {
      return api.getComment(id);
    },
    {
      staleTime: Infinity,
    }
  );
};

export default useComment;
