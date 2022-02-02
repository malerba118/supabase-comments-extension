# Supabase Comments Extension

## Installation

Not yet available but coming soon :)

```bash
npm install --save supabase-comments-extension @supabase/ui @supabase/supabase-js react-query
```

## Basic Usage

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
  CommentsProvider,
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
      accentColor="pink"
    >
      <AuthModal
        visible={modalVisible}
        onAuthenticate={() => setModalVisible(false)}
        onClose={() => setModalVisible(false)}
      />
      <Comments topic="tutorial-one" />
    </CommentsProvider>
  );
};
```

## Usage Without Auth

If you already have an app set up with Supabase authentication,
then you can skip the AuthModal and direct the user to your
existing sign-in system.

```jsx
import { useState } from 'react';
import { createClient } from '@supabase/supabase-js';
import { Comments, CommentsProvider } from 'supabase-comments-extension';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const App = () => {
  return (
    <CommentsProvider
      supabaseClient={supabase}
      onAuthRequested={() => {
        window.location.href = '/sign-in';
      }}
    >
      <Comments topic="tutorial-one" />
    </CommentsProvider>
  );
};
```

## Bring Your Own Reactions

You can add your own reactions/emojis by adding rows to the `sce_reactions` table.

It's easy to add rows via the supabase dashboard or if you prefer you can write some sql to insert new rows.

```sql
insert into sce_reactions(type, label, url) values ('heart', 'Heart', 'https://emojis.slackmojis.com/emojis/images/1596061862/9845/meow_heart.png?1596061862');
insert into sce_reactions(type, label, url) values ('like', 'Like', 'https://emojis.slackmojis.com/emojis/images/1588108689/8789/fb-like.png?1588108689');
insert into sce_reactions(type, label, url) values ('party-blob', 'Party Blob', 'https://emojis.slackmojis.com/emojis/images/1547582922/5197/party_blob.gif?1547582922');
```

## Custom Reaction Rendering

If you want to customize the way comment reactions are rendered then you're in luck!
You can pass your own `CommentReactions` component to control exactly how reactions are rendered beneath each comment.
