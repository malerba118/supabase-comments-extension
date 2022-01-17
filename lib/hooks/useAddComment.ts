import { useMutation, useQueryClient } from "react-query";
import * as api from "../api";

interface UseAddCommentPayload {
  comment: string;
  topic: string;
  parentId: string | null;
}

const useAddComment = () => {
  const queryClient = useQueryClient();

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
