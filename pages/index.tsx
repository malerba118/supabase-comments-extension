import supabase from "@/services/supabase";
import { Auth, Button } from "@supabase/ui";
import type { NextPage } from "next";
import styles from "../styles/Home.module.css";
import { QueryClient, QueryClientProvider } from "react-query";
import { Comments } from "@/lib";
import { FC, useEffect } from "react";

const queryClient = new QueryClient();

const Home: NextPage = () => {
  const auth = Auth.useUser();

  return (
    <QueryClientProvider client={queryClient}>
      <div className={styles.container}>
        {!auth.user && <Auth supabaseClient={supabase} />}
        {auth.user && (
          <div>
            <Button
              onClick={() =>
                supabase.auth.signOut().then(() => window.location.reload())
              }
            >
              Log Out
            </Button>
            <Comments topic="tutorial-one" />
          </div>
        )}
      </div>
    </QueryClientProvider>
  );
};

export default Home;
