# Supabase Comments Extension

Add a robust comment system to your react app in less than 5 minutes!

This library provides comments, replies, reactions, mentions, and authentication all out of the box.

## Demos

<!-- Choose your flavor: -->
  - https://malerba118.github.io/supabase-comments-extension
  - https://codesandbox.io/s/supabase-comments-extension-demo-8hg9s?file=/src/App.tsx

## Getting Started


First things first, this project is powered by [supabase](https://supabase.com/) so if you don't already have a supabase db, [head over there and make one](https://app.supabase.io/) (it's super simple and literally takes a few seconds)

### Installation

```bash
npm install --save supabase-comments-extension @supabase/ui @supabase/supabase-js react-query
```

### Running Migrations 

Once you've got yourself a supabase db, you'll need to add a few tables and other sql goodies to it with the following command

```bash
npx supabase-comments-extension run-migrations <supabase-connection-string>
```

You can find your connection string on the supabase dashboard: https://app.supabase.io/project/PUT-YOUR-PROJECT-ID-HERE/settings/database

It should look something like this: `postgresql://postgres:some-made-up-password@db.ddziybrgjepxqpsflsiv.supabase.co:5432/postgres`

### Usage With Auth

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

### Usage Without Auth

If you already have an app set up with supabase authentication,
then you can skip the `AuthModal` and direct the user to your
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

## Advanced Features

supabase-comments-extension includes a handful of customization options to meet your app's needs

### Bring Your Own Reactions

You can add your own reactions by adding rows to the `sce_reactions` table.

<img width="838" alt="Screen Shot 2022-02-01 at 4 31 55 PM" src="https://user-images.githubusercontent.com/5760059/152088763-8de5ac3f-ebc6-4337-8ad7-073ce63b288b.png">

It's easy to add rows via the supabase dashboard or if you prefer you can write some sql to insert new rows.

```sql
insert into sce_reactions(type, label, url) values ('heart', 'Heart', 'https://emojis.slackmojis.com/emojis/images/1596061862/9845/meow_heart.png?1596061862');
insert into sce_reactions(type, label, url) values ('like', 'Like', 'https://emojis.slackmojis.com/emojis/images/1588108689/8789/fb-like.png?1588108689');
insert into sce_reactions(type, label, url) values ('party-blob', 'Party Blob', 'https://emojis.slackmojis.com/emojis/images/1547582922/5197/party_blob.gif?1547582922');
```

### Custom Reaction Rendering

If you want to customize the way comment reactions are rendered then you're in luck!
You can pass your own `CommentReactions` component to control exactly how reactions are rendered beneath each comment.

```tsx
import { useState } from 'react';
import { createClient } from '@supabase/supabase-js';
import { Button } from '@supabase/ui';
import {
  Comments,
  CommentsProvider,
  CommentReactionsProps,
} from 'supabase-comments-extension';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

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

const App = () => {
  return (
    <CommentsProvider
      supabaseClient={supabase}
      components={{
        CommentReactions: CustomCommentReactions,
      }}
    >
      <Comments topic="custom-reactions" />
    </CommentsProvider>
  );
};
```

The above code will render the following ui

<img width="548" alt="Screen Shot 2022-02-01 at 8 34 33 PM" src="https://user-images.githubusercontent.com/5760059/152089497-515113e0-5281-4a2e-8c58-5f8c2e40f812.png">

### Handling Mentions

This library includes support for mentions, however mentions are fairly useless without a way to notify the users who are mentioned. You can listen to mentions via postgres triggers and perform some action in response such as insert into a notifications table or send an http request to a custom endpoint.

```sql
CREATE OR REPLACE FUNCTION notify_mentioned_users()
  RETURNS trigger AS
$$
DECLARE
  mentioned_user_id uuid;
BEGIN
  FOREACH mentioned_user_id IN ARRAY NEW.mentioned_user_ids LOOP
	  INSERT INTO your_notifications_table (actor, action, receiver) VALUES(NEW.user_id, 'mention', mentioned_user_id);
  END LOOP;
RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER comment_insert_trigger
  AFTER INSERT
  ON sce_comments
  FOR EACH ROW
  EXECUTE PROCEDURE notify_mentioned_users();
```

If you don't care about mentions, then you can disable them via the `CommentsProvider`

```tsx
<CommentsProvider supabaseClient={supabase} enableMentions={false}>
  <Comments topic="mentions-disabled" />
</CommentsProvider>
```
