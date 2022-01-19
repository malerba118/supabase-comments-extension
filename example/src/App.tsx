import React from 'react';
import { Auth, Button } from '@supabase/ui';
import { Comments, CommentsProvider } from 'supabase-comments-extension';
import supabase from './supabase';

const App = () => {
  const auth = Auth.useUser();

  return (
    <CommentsProvider supabaseClient={supabase}>
      <div>
        {!auth.user && <Auth supabaseClient={supabase} />}
        {auth.user && (
          <div>
            <nav className="flex items-center justify-end h-16">
              <div>
                <Button
                  onClick={() =>
                    supabase.auth.signOut().then(() => window.location.reload())
                  }
                >
                  Log Out
                </Button>
              </div>
            </nav>
            <div className="max-w-lg mx-auto my-12">
              <Comments topic="tutorial-one" />
            </div>
          </div>
        )}
      </div>
    </CommentsProvider>
  );
};

export default App;
