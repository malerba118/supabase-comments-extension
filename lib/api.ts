import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL as string,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY as string
);

interface Comment {
  id: string;
  user_id: string;
  parent_id: string | null;
  topic: string;
  comment: string;
  created_at: string;
  replies_count: number;
}

export const assertResponseOk = (response: { error: any }) => {
  if (response.error) {
    throw new ApiError(response.error);
  }
};

export class ApiError extends Error {
  type = "ApiError";
  message: string;
  details: string;
  hint: string;
  code: string;
  constructor(error: any) {
    super(error.message);
    this.message = error.message;
    this.details = error.details;
    this.hint = error.hint;
    this.code = error.code;
  }
}

interface GetCommentsOptions {
  topic: string;
  parentId?: string | null;
}

export const getComments = async ({
  topic,
  parentId,
}: GetCommentsOptions): Promise<Comment[]> => {
  const query = supabase
    .from<Comment>("comments_with_metadata")
    .select("*")
    .eq("topic", topic);
  if (parentId) {
    query.eq("parent_id", parentId);
  }
  const response = await query;
  assertResponseOk(response);
  return response.data as Comment[];
};

export const getComment = async (id: string): Promise<Comment> => {
  const query = supabase
    .from<Comment>("comments_with_metadata")
    .select("*")
    .eq("id", id)
    .single();

  const response = await query;
  assertResponseOk(response);
  return response.data as Comment;
};
