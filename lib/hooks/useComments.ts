import { useQuery, useQueryClient } from "react-query";
import * as api from "../api";

interface UseCommentsOptions {
  topic: string;
  parentId?: string | null;
}

const useComments = ({ topic, parentId }: UseCommentsOptions) => {
  const queryClient = useQueryClient();
  return useQuery(
    ["comments", { topic, parentId }],
    () => {
      return api.getComments({ topic, parentId });
    },
    {
      onSuccess: (data) => {
        data?.forEach((comment) => {
          queryClient.setQueryData(["comments", comment.id], comment);
        });
      },
    }
  );
};

export default useComments;
