import { createClient } from '@supabase/supabase-js';

// const SUPABASE_URL = 'http://localhost:54321';
// const SUPABASE_ANON_KEY =
//   'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiJ9.ZopqoUt20nEV9cklpv9e3yw3PVyZLmKs5qLD6nGL1SI';

const SUPABASE_URL = 'https://cdayanxkvcxugtlatoaa.supabase.co';
const SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlhdCI6MTYzOTM0MjE1MiwiZXhwIjoxOTU0OTE4MTUyfQ.pXXLHtODLQLrwYQcIXxUFuv-UQVnZNgIKjMjLlZI-EA';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  autoRefreshToken: true,
});

export default supabase;
