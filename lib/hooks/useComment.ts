import { useQuery, useQueryClient } from "react-query";
import * as api from "../api";

const useComments = (id: string) => {
  const queryClient = useQueryClient();
  return useQuery(["comments", id], () => {
    return api.getComment(id);
  });
};

export default useComments;
