import supabase from "@/services/supabase";
import { Auth, Button } from "@supabase/ui";
import type { NextPage } from "next";
import styles from "../styles/Home.module.css";
import { QueryClient, QueryClientProvider } from "react-query";
import { useComments } from "@/lib";
import { FC } from "react";

const queryClient = new QueryClient();

const Comments: FC<any> = () => {
  const queries = {
    comments: useComments({ topic: "tutorial-one" }),
  };
  return <div>{JSON.stringify(queries.comments.data)}</div>;
};

const Home: NextPage = () => {
  const auth = Auth.useUser();
  return (
    <QueryClientProvider client={queryClient}>
      <div className={styles.container}>
        {!auth.user && <Auth supabaseClient={supabase} />}
        {auth.user && (
          <div>
            <Button onClick={() => supabase.auth.signOut()}>Log Out</Button>
            <Comments />
          </div>
        )}
      </div>
    </QueryClientProvider>
  );
};

export default Home;
