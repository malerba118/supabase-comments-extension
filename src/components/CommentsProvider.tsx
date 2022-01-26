import { QueryClient, QueryClientProvider } from 'react-query';
import React, { createContext, FC, useContext, useMemo } from 'react';
import { SupabaseClient } from '@supabase/supabase-js';
import { DisplayUser } from '../api';
import { Auth } from '@supabase/ui';

const defaultQueryClient = new QueryClient();

const SupabaseClientContext = createContext<SupabaseClient | null>(null);

export const useSupabaseClient = () => {
  const supabaseClient = useContext(SupabaseClientContext);
  if (!supabaseClient) {
    throw new Error(
      'No supabase client found. Make sure this code is contained in a CommentsProvider.'
    );
  }
  return supabaseClient;
};

interface CommentsContextApi {
  onAuthRequested?: () => void;
  onUserClick?: (user: DisplayUser) => void;
  mode: 'light' | 'dark';
}

const CommentsContext = createContext<CommentsContextApi | null>(null);

export const useCommentsContext = () => {
  const context = useContext(CommentsContext);
  if (!context) {
    throw new Error(
      'CommentsProvider not found. Make sure this code is contained in a CommentsProvider.'
    );
  }
  return context;
};

interface CommentsProviderProps {
  queryClient?: QueryClient;
  supabaseClient: SupabaseClient;
  onAuthRequested?: () => void;
  onUserClick?: (user: DisplayUser) => void;
  mode?: 'light' | 'dark';
}

const CommentsProvider: FC<CommentsProviderProps> = ({
  queryClient = defaultQueryClient,
  supabaseClient,
  children,
  onAuthRequested,
  onUserClick,
  mode = 'light',
}) => {
  const context = useMemo(
    () => ({
      onAuthRequested,
      onUserClick,
      mode,
    }),
    [onAuthRequested, onUserClick, mode]
  );

  return (
    <QueryClientProvider client={queryClient}>
      <SupabaseClientContext.Provider value={supabaseClient}>
        <Auth.UserContextProvider supabaseClient={supabaseClient}>
          <CommentsContext.Provider value={context}>
            {children}
          </CommentsContext.Provider>
        </Auth.UserContextProvider>
      </SupabaseClientContext.Provider>
    </QueryClientProvider>
  );
};

export default CommentsProvider;
