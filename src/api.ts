import { SupabaseClient } from '@supabase/supabase-js';

const timeout = (ms: number) =>
  new Promise((resolve) => setTimeout(resolve, ms));

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
  mentioned_user_ids: string[];
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
  user: DisplayUser;
}

export const assertResponseOk = (response: { error: any }) => {
  if (response.error) {
    throw new ApiError(response.error);
  }
};

export class ApiError extends Error {
  type = 'ApiError';
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

export interface GetCommentsOptions {
  topic: string;
  parentId: string | null;
}

export interface AddCommentPayload {
  comment: string;
  topic: string;
  parent_id: string | null;
  mentioned_user_ids: string[];
}

export interface UpdateCommentPayload {
  comment: string;
  mentioned_user_ids: string[];
}

export interface GetCommentReactionsOptions {
  reaction_type: string;
  comment_id: string;
}

export interface AddCommentReactionPayload {
  reaction_type: string;
  comment_id: string;
}

export interface RemoveCommentReactionPayload {
  reaction_type: string;
  comment_id: string;
}

export const createApiClient = (supabase: SupabaseClient) => {
  const getComments = async ({
    topic,
    parentId = null,
  }: GetCommentsOptions): Promise<Comment[]> => {
    const query = supabase
      .from<Comment>('comments_with_metadata')
      .select(
        '*,user:display_users!user_id(*),reactions_metadata:comment_reactions_metadata(*)'
      )
      .eq('topic', topic)
      .order('created_at', { ascending: true });

    if (parentId) {
      query.eq('parent_id', parentId);
    } else {
      query.is('parent_id', null);
    }
    const response = await query;
    await timeout(1200);

    assertResponseOk(response);
    return response.data as Comment[];
  };

  const getComment = async (id: string): Promise<Comment> => {
    const query = supabase
      .from<Comment>('comments_with_metadata')
      .select(
        '*,user:display_users!user_id(*),reactions_metadata:comment_reactions_metadata(*)'
      )
      .eq('id', id)
      .single();

    const response = await query;
    assertResponseOk(response);
    return response.data as Comment;
  };

  const addComment = async (payload: AddCommentPayload): Promise<Comment> => {
    const query = supabase
      .from('comments')
      .insert({
        ...payload,
        user_id: supabase.auth.user()?.id,
      })
      .single();

    const response = await query;
    assertResponseOk(response);
    return response.data as Comment;
  };

  const updateComment = async (
    id: string,
    payload: UpdateCommentPayload
  ): Promise<Comment> => {
    const query = supabase
      .from('comments')
      .update(payload)
      .match({ id })
      .single();

    const response = await query;
    assertResponseOk(response);
    return response.data as Comment;
  };

  const deleteComment = async (id: string): Promise<Comment> => {
    const query = supabase.from('comments').delete().match({ id }).single();

    const response = await query;
    assertResponseOk(response);
    return response.data as Comment;
  };

  const getReactions = async (): Promise<Reaction[]> => {
    const query = supabase.from<Reaction>('reactions').select('*');

    const response = await query;
    assertResponseOk(response);
    return response.data as Reaction[];
  };

  const getReaction = async (type: string): Promise<Reaction> => {
    const query = supabase
      .from<Reaction>('reactions')
      .select('*')
      .eq('type', type)
      .single();

    const response = await query;
    assertResponseOk(response);
    return response.data as Reaction;
  };

  const getCommentReactions = async ({
    reaction_type,
    comment_id,
  }: GetCommentReactionsOptions): Promise<CommentReaction[]> => {
    const query = supabase
      .from('comment_reactions')
      .select('*,user:display_users!user_id(*)')
      .eq('comment_id', comment_id)
      .eq('reaction_type', reaction_type);

    const response = await query;
    assertResponseOk(response);
    return response.data as CommentReaction[];
  };

  const addCommentReaction = async (
    payload: AddCommentReactionPayload
  ): Promise<CommentReaction> => {
    const query = supabase
      .from('comment_reactions')
      .insert({
        ...payload,
        user_id: supabase.auth.user()?.id,
      })
      .single();

    const response = await query;
    assertResponseOk(response);
    return response.data as CommentReaction;
  };

  const removeCommentReaction = async ({
    reaction_type,
    comment_id,
  }: RemoveCommentReactionPayload): Promise<CommentReaction> => {
    const query = supabase
      .from('comment_reactions')
      .delete({ returning: 'representation' })
      .match({ reaction_type, comment_id, user_id: supabase.auth.user()?.id })
      .single();

    const response = await query;
    assertResponseOk(response);
    return response.data as CommentReaction;
  };

  const searchUsers = async (search: string): Promise<DisplayUser[]> => {
    const query = supabase
      .from<DisplayUser>('display_users')
      .select('*')
      .ilike('name', `%${search}%`);

    const response = await query;
    assertResponseOk(response);
    return response.data as DisplayUser[];
  };

  return {
    getComments,
    getComment,
    addComment,
    updateComment,
    deleteComment,
    getReactions,
    getReaction,
    getCommentReactions,
    addCommentReaction,
    removeCommentReaction,
    searchUsers,
  };
};
