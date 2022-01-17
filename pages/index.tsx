import type { NextPage } from "next";
import dynamic from "next/dynamic";

const Home = dynamic(() => import("../components/Home"), {
  ssr: false,
});

const IndexPage: NextPage = () => {
  return <Home />;
};

export default IndexPage;
