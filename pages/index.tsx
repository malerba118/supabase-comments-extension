import supabase from "@/services/supabase";
import { Auth, Button } from "@supabase/ui";
import type { NextPage } from "next";
import styles from "../styles/Home.module.css";
import { QueryClient, QueryClientProvider } from "react-query";

const queryClient = new QueryClient();

const Home: NextPage = () => {
  const auth = Auth.useUser();
  return (
    <QueryClientProvider client={queryClient}>
      <div className={styles.container}>
        {!auth.user && <Auth supabaseClient={supabase} />}
        {auth.user && (
          <Button onClick={() => supabase.auth.signOut()}>Log Out</Button>
        )}
      </div>
    </QueryClientProvider>
  );
};

export default Home;
