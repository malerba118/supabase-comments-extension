import React, { useEffect, useState, FC, useLayoutEffect } from 'react';
import { Auth, Button, Menu } from '@supabase/ui';
import {
  Comments,
  CommentsProvider,
  AuthModal,
} from 'supabase-comments-extension';
import supabase from './supabase';

interface Example {
  key: string;
  label: string;
  Component: FC<{
    topic: string;
  }>;
}

const examples: Record<string, Example> = {
  basic: {
    key: 'basic',
    label: 'Basic',
    Component: () => {
      return (
        <CommentsProvider
          supabaseClient={supabase}
          onAuthRequested={() => {
            window.alert('Auth Requested');
          }}
          onUserClick={(user) => {
            window.alert(user.name);
          }}
        >
          <div className="max-w-lg mx-auto my-12">
            <Comments topic="basic" />
          </div>
        </CommentsProvider>
      );
    },
  },
  darkMode: {
    key: 'darkMode',
    label: 'Dark Mode',
    Component: () => {
      useLayoutEffect(() => {
        const prevColor = document.body.style.backgroundColor;
        document.body.style.backgroundColor = '#181818';
        return () => {
          document.body.style.backgroundColor = prevColor;
        };
      }, []);

      return (
        <CommentsProvider
          supabaseClient={supabase}
          mode="dark"
          onAuthRequested={() => {
            window.alert('Auth Requested');
          }}
          onUserClick={(user) => {
            window.alert(user.name);
          }}
          // accentColor="#E500D7"
        >
          <div className="max-w-lg mx-auto my-12">
            <Comments topic="dark-mode" />
          </div>
        </CommentsProvider>
      );
    },
  },
  withAuth: {
    key: 'withAuth',
    label: 'With AuthModal',
    Component: () => {
      const [modalVisible, setModalVisible] = useState(false);

      return (
        <CommentsProvider
          supabaseClient={supabase}
          onAuthRequested={() => {
            setModalVisible(true);
          }}
          onUserClick={(user) => {
            window.alert(user.name);
          }}
          accentColor="#8405FF"
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
          <div className="max-w-lg mx-auto my-12">
            <Comments topic="with-auth-modal" />
          </div>
        </CommentsProvider>
      );
    },
  },
};

const Sidenav = ({ activeExample, onExampleChange }: any) => {
  return (
    <Menu>
      <Menu.Misc>
        <h3 className="p-4 font-bold border-b-2 h-14 border-alpha-10 text-md">
          supabase-comments-extension
        </h3>
      </Menu.Misc>
      {Object.values(examples).map((ex) => (
        <Menu.Item
          onClick={() => {
            onExampleChange(ex.key);
          }}
          key={ex.key}
          active={ex.key === activeExample}
        >
          {ex.label}
        </Menu.Item>
      ))}
    </Menu>
  );
};

const App = () => {
  const auth = Auth.useUser();
  const [modalVisible, setModalVisible] = useState(false);
  const [activeExample, setActiveExample] = useState('basic');

  const Component = examples[activeExample].Component;

  return (
    <div className="flex h-screen">
      <div className="w-[280px] border-r-2 border-alpha-10">
        <Sidenav
          activeExample={activeExample}
          onExampleChange={setActiveExample}
        />
      </div>
      <div className="flex flex-col flex-1">
        <nav className="flex items-center justify-end px-4 border-b-2 h-14 border-alpha-10">
          <CommentsProvider supabaseClient={supabase}>
            <AuthModal
              visible={modalVisible}
              onAuthenticate={() => {
                setModalVisible(false);
              }}
              onClose={() => {
                setModalVisible(false);
              }}
            />
          </CommentsProvider>
          {!auth.user && (
            <div>
              <Button onClick={() => setModalVisible(true)}>Sign in</Button>
            </div>
          )}
          {auth.user && (
            <div>
              <Button onClick={() => supabase.auth.signOut()}>Sign Out</Button>
            </div>
          )}
        </nav>
        <div className="flex-1 overflow-y-auto">
          <Component key={activeExample} topic={activeExample} />
        </div>
      </div>
    </div>
  );
};

export default App;
