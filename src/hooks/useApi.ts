import { useMemo } from 'react';
import { createApiClient } from '../api';
import { useSupabaseClient } from '../components/CommentsProvider';

const useApi = () => {
  const supabase = useSupabaseClient();
  const api = useMemo(() => createApiClient(supabase), [supabase]);
  return api;
};

export default useApi;
