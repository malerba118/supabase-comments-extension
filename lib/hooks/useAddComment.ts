import { useMutation, useQueryClient } from "react-query";
import useApi from "./useApi";

interface UseAddCommentPayload {
  comment: string;
  topic: string;
  parentId: string | null;
}

const useAddComment = () => {
  const queryClient = useQueryClient();
  const api = useApi();

  return useMutation(
    ({ comment, topic, parentId }: UseAddCommentPayload) => {
      return api.addComment({ comment, topic, parent_id: parentId });
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries(["comments"]);
      },
    }
  );
};

export default useAddComment;
