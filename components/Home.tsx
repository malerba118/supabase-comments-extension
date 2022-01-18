import supabase from "@/services/supabase";
import { Auth, Button } from "@supabase/ui";
import styles from "../styles/Home.module.css";
import { Comments, CommentsProvider } from "@/lib";

const Home = () => {
  const auth = Auth.useUser();

  return (
    <CommentsProvider supabaseClient={supabase}>
      <div className={styles.container}>
        {!auth.user && <Auth supabaseClient={supabase} />}
        {auth.user && (
          <div>
            <nav className="flex h-16 justify-end items-center">
              <div>
                <Button
                  onClick={() =>
                    supabase.auth.signOut().then(() => window.location.reload())
                  }
                >
                  Log Out
                </Button>
              </div>
            </nav>
            <div className="max-w-lg mx-auto my-12">
              <Comments topic="tutorial-one" />
            </div>
          </div>
        )}
      </div>
    </CommentsProvider>
  );
};

export default Home;
