import React, { useEffect, useState } from 'react';
import { Auth, Button } from '@supabase/ui';
import { Comments, CommentsProvider } from 'supabase-comments-extension';
import supabase from './supabase';
import AuthModal from './AuthModal';

const App = () => {
  const auth = Auth.useUser();
  const [authRequested, setAuthRequested] = useState(false);

  useEffect(() => {
    if (auth.user) {
      setAuthRequested(false);
    }
  }, [auth.user]);

  return (
    <CommentsProvider
      onUserClick={(user) => {
        // console.log(user);
        alert('hi');
      }}
      onAuthRequested={() => {
        setAuthRequested(true);
      }}
      supabaseClient={supabase}
      mode="dark"
      accentColor="rgb(36, 180, 126)"
    >
      <AuthModal
        visible={authRequested && !auth.user}
        onClose={() => {
          setAuthRequested(false);
        }}
        supabaseClient={supabase}
      />
      <div>
        <div>
          <nav className="flex items-center justify-end h-16 px-4">
            {auth.user && (
              <div>
                <Button onClick={() => supabase.auth.signOut()}>Log Out</Button>
              </div>
            )}
          </nav>
          <div className="max-w-lg mx-auto my-12">
            <Comments topic="tutorial-one" />
          </div>
        </div>
      </div>
    </CommentsProvider>
  );
};

export default App;
