import { QueryClient, QueryClientProvider } from 'react-query';
import React, { createContext, FC, useContext, useMemo } from 'react';
import { SupabaseClient } from '@supabase/supabase-js';
import { DisplayUser } from '../api';

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

interface CallbacksContextApi {
  onAuthRequested?: () => void;
  onUserClick?: (user: DisplayUser) => void;
}

const CallbacksContext = createContext<CallbacksContextApi | null>(null);

export const useCallbacks = () => {
  const callbacks = useContext(CallbacksContext);
  if (!callbacks) {
    throw new Error(
      'CommentsProvider not found. Make sure this code is contained in a CommentsProvider.'
    );
  }
  return callbacks;
};

interface CommentsProviderProps {
  queryClient?: QueryClient;
  supabaseClient: SupabaseClient;
  onAuthRequested?: () => void;
  onUserClick?: (user: DisplayUser) => void;
}

const CommentsProvider: FC<CommentsProviderProps> = ({
  queryClient = defaultQueryClient,
  supabaseClient,
  children,
  onAuthRequested,
  onUserClick,
}) => {
  const callbacks = useMemo(
    () => ({
      onAuthRequested,
      onUserClick,
    }),
    [onAuthRequested, onUserClick]
  );

  return (
    <QueryClientProvider client={queryClient}>
      <SupabaseClientContext.Provider value={supabaseClient}>
        <CallbacksContext.Provider value={callbacks}>
          {children}
        </CallbacksContext.Provider>
      </SupabaseClientContext.Provider>
    </QueryClientProvider>
  );
};

export default CommentsProvider;
