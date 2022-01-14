import "../styles/globals.css";
import type { AppProps } from "next/app";
import supabase from "@/services/supabase";
import { Auth } from "@supabase/ui";

function MyApp({ Component, pageProps }: AppProps) {
  return (
    <Auth.UserContextProvider supabaseClient={supabase}>
      <Component {...pageProps} />
    </Auth.UserContextProvider>
  );
}

export default MyApp;
