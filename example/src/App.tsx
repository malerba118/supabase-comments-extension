import React, { useEffect, useState } from 'react';
import { Auth, Button } from '@supabase/ui';
import {
  Comments,
  CommentsProvider,
  AuthModal,
} from 'supabase-comments-extension';
import supabase from './supabase';

const App = () => {
  const auth = Auth.useUser();
  const [modalVisible, setModalVisible] = useState(false);

  return (
    <CommentsProvider
      onUserClick={(user) => {
        // console.log(user);
        alert('hi');
      }}
      onAuthRequested={() => {
        setModalVisible(true);
      }}
      supabaseClient={supabase}
      mode="dark"
      accentColor="rgb(36, 180, 126)"
    >
      <AuthModal
        visible={modalVisible}
        onAuthenticate={() => {
          setModalVisible(false);
        }}
        onClose={() => {
          setModalVisible(false);
        }}
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
