import { QueryClient, QueryClientProvider } from 'react-query';
import React, { createContext, FC, useContext } from 'react';
import { SupabaseClient } from '@supabase/supabase-js';

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

const defaultQueryClient = new QueryClient();

interface CommentsProviderProps {
  queryClient?: QueryClient;
  supabaseClient: SupabaseClient;
}

const CommentsProvider: FC<CommentsProviderProps> = ({
  queryClient = defaultQueryClient,
  supabaseClient,
  children,
}) => {
  return (
    <QueryClientProvider client={queryClient}>
      <SupabaseClientContext.Provider value={supabaseClient}>
        {children}
      </SupabaseClientContext.Provider>
    </QueryClientProvider>
  );
};

export default CommentsProvider;
