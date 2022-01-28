# Supabase Comments Extension

## Installation

Not yet available but coming soon :)

```bash
npm install --save supabase-comments-extension @supabase/ui @supabase/supabase-js react-query
```

## Usage
This is roughly how the API will look upon completion.


First you'll need to add required tables and sql goodies to your supabase db

```bash
supabase-comments-extension run-migrations <supabase-connection-string>
```

Then in your app code you can add comments with the following

```jsx
import { useState } from 'react';
import { createClient } from '@supabase/supabase-js';
import {
  Comments,
  AuthModal, 
  CommentsProvider
} from 'supabase-comments-extension';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY); 

const App = () => {
  const [modalVisible, setModalVisible] = useState(false);

  return (
    <CommentsProvider
      supabaseClient={supabase}
      onUserClick={(user) => {
        // go to user page or do whatever you want
      }}
      onAuthRequested={() => setModalVisible(true)}
      mode="dark"
      accentColor="green"
    >
      <AuthModal 
        visible={modalVisible} 
        onAuthenticate={() => setModalVisible(false)} 
        onClose={() => setModalVisible(false)} 
      />
      <Comments topic="tutorial-one" />
    </CommentsProvider>
  )
}
```
