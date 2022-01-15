import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL as string,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY as string
);

export interface CommentReactionMetadata {
  comment_id: string;
  reaction_type: string;
  reaction_count: string;
  active_for_user: boolean;
}

export interface DisplayUser {
  id: string;
  name: string;
  avatar: string;
}

export interface Comment {
  id: string;
  user_id: string;
  parent_id: string | null;
  topic: string;
  comment: string;
  created_at: string;
  replies_count: number;
  reactions_metadata: CommentReactionMetadata[];
  user: DisplayUser;
}

export interface Reaction {
  type: string;
  created_at: string;
  metadata: any;
}

export interface CommentReaction {
  id: string;
  user_id: string;
  comment_id: string;
  reaction_type: string;
  created_at: string;
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
  parentId: string | null;
}

export const getComments = async ({
  topic,
  parentId = null,
}: GetCommentsOptions): Promise<Comment[]> => {
  const query = supabase
    .from<Comment>("comments_with_metadata")
    .select(
      "*,user:display_users!user_id(*),reactions_metadata:comment_reactions_metadata(*)"
    )
    .eq("topic", topic);

  if (parentId) {
    query.eq("parent_id", parentId);
  } else {
    query.is("parent_id", null);
  }
  const response = await query;
  assertResponseOk(response);
  return response.data as Comment[];
};

export const getComment = async (id: string): Promise<Comment> => {
  const query = supabase
    .from<Comment>("comments_with_metadata")
    .select(
      "*,user:display_users!user_id(*),reactions_metadata:comment_reactions_metadata(*)"
    )
    .eq("id", id)
    .single();

  const response = await query;
  assertResponseOk(response);
  return response.data as Comment;
};

export const getReactions = async (): Promise<Reaction[]> => {
  const query = supabase.from<Reaction>("reactions").select("*");

  const response = await query;
  assertResponseOk(response);
  return response.data as Reaction[];
};

export const getReaction = async (type: string): Promise<Reaction> => {
  const query = supabase
    .from<Reaction>("reactions")
    .select("*")
    .eq("type", type)
    .single();

  const response = await query;
  assertResponseOk(response);
  return response.data as Reaction;
};

interface AddCommentReactionPayload {
  reaction_type: string;
  comment_id: string;
}

export const addCommentReaction = async (
  payload: AddCommentReactionPayload
): Promise<CommentReaction> => {
  const query = supabase
    .from("comment_reactions")
    .insert({
      ...payload,
      user_id: supabase.auth.user()?.id,
    })
    .single();

  const response = await query;
  assertResponseOk(response);
  return response.data as CommentReaction;
};

interface RemoveCommentReactionPayload {
  reaction_type: string;
  comment_id: string;
}

export const removeCommentReaction = async ({
  reaction_type,
  comment_id,
}: RemoveCommentReactionPayload): Promise<CommentReaction> => {
  const query = supabase
    .from("comment_reactions")
    .delete({ returning: "representation" })
    .match({ reaction_type, comment_id, user_id: supabase.auth.user()?.id })
    .single();

  const response = await query;
  assertResponseOk(response);
  return response.data as CommentReaction;
};

interface GetCommentReactionMetadataOptions {
  commentId: string;
  reactionType: string;
}

export const getCommentReactionMetadata = async ({
  commentId,
  reactionType,
}: GetCommentReactionMetadataOptions): Promise<CommentReactionMetadata> => {
  const query = supabase
    .from<CommentReactionMetadata>("comment_reactions_metadata")
    .select("*")
    .eq("comment_id", commentId)
    .eq("reaction_type", reactionType)
    .single();
  const response = await query;
  assertResponseOk(response);
  return response.data as CommentReactionMetadata;
};
