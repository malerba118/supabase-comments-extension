import React, { useEffect, useState, FC, useLayoutEffect } from 'react';
import { Auth, Button, Menu } from '@supabase/ui';
import {
  Comments,
  CommentsProvider,
  AuthModal,
  CommentReactionsProps,
} from 'supabase-comments-extension';
import supabase from './supabase';
import AceEditor from 'react-ace';

import 'ace-builds/src-noconflict/theme-twilight';
import 'ace-builds/src-noconflict/mode-javascript';
import 'ace-builds/src-noconflict/mode-jsx';
import 'ace-builds/src-noconflict/mode-tsx';

interface Example {
  key: string;
  label: string;
  Component: FC<{
    topic: string;
  }>;
  code: string;
}

const CustomCommentReactions: FC<CommentReactionsProps> = ({
  activeReactions,
  toggleReaction,
}) => {
  return (
    <Button className="!py-0.5" onClick={() => toggleReaction('like')}>
      {activeReactions.has('like') ? 'unlike' : 'like'}
    </Button>
  );
};

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
          onError={console.log}
        >
          <div className="max-w-lg mx-auto my-12">
            <Comments topic="basic" />
          </div>
        </CommentsProvider>
      );
    },
    code: `const App = () => {
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
};`,
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
        >
          <div className="max-w-lg mx-auto my-12">
            <Comments topic="dark-mode" />
          </div>
        </CommentsProvider>
      );
    },
    code: `const App = () => {
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
    >
      <div className="max-w-lg mx-auto my-12">
        <Comments topic="dark-mode" />
      </div>
    </CommentsProvider>
  );
};`,
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
            providers={['twitter']}
            redirectTo={
              process.env.NODE_ENV === 'development'
                ? 'http://localhost:3000'
                : 'https://malerba118.github.io/supabase-comments-extension'
            }
          />
          <div className="max-w-lg mx-auto my-12">
            <Comments topic="with-auth-modal" />
          </div>
        </CommentsProvider>
      );
    },
    code: `const App = () => {
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
};`,
  },
  customReactions: {
    key: 'customReactions',
    label: 'Custom Reactions',
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
          components={{
            CommentReactions: CustomCommentReactions,
          }}
        >
          <div className="max-w-lg mx-auto my-12">
            <Comments topic="custom-reactions" />
          </div>
        </CommentsProvider>
      );
    },
    code: `const CustomCommentReactions: FC<CommentReactionsProps> = ({ 
  activeReactions, 
  toggleReaction 
}) => {
  return (
    <Button className="!py-0.5" onClick={() => toggleReaction('like')}>
      {activeReactions.has('like') ? 'unlike' : 'like'}
    </Button>
  );
};

const App = () => {
  return (
    <CommentsProvider
      supabaseClient={supabase}
      onAuthRequested={() => {
        window.alert('Auth Requested');
      }}
      onUserClick={(user) => {
        window.alert(user.name);
      }}
      components={{
        CommentReactions: CustomCommentReactions,
      }}
    >
      <div className="max-w-lg mx-auto my-12">
        <Comments topic="custom-reactions" />
      </div>
    </CommentsProvider>
  );
};`,
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
  const code = examples[activeExample].code;

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
              providers={['twitter']}
              redirectTo={
                process.env.NODE_ENV === 'development'
                  ? 'http://localhost:3000'
                  : 'https://malerba118.github.io/supabase-comments-extension'
              }
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
          <AceEditor
            mode="tsx"
            theme="twilight"
            value={code}
            name={activeExample}
            editorProps={{ $blockScrolling: true }}
            scrollMargin={[10, 10]}
            readOnly
            height="380px"
            width="650px"
            className="w-full max-w-xl mx-auto my-12 border-2 rounded-lg border-alpha-10"
          />
          <Component key={activeExample} topic={activeExample} />
        </div>
      </div>
    </div>
  );
};

export default App;
