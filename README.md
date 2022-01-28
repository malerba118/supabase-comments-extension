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
<CommentsProvider
  supabaseClient={supabase}
  onUserClick={(user) => {
    // go to user page
  }}
  onAuthRequested={() => {
    // go to login page
  }}
  mode="dark"
  accentColor="green"
>
  <Comments topic="tutorial-one" />
</CommentsProvider>
```
