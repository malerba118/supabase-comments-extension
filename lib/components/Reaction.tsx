import { FC } from "react";
import { Image } from "@supabase/ui";
import { useReaction } from "../hooks";

interface ReactionProps {
  type: string;
}

const Reaction: FC<ReactionProps> = ({ type }) => {
  const query = useReaction(type);

  return (
    <Image
      className="h-4 w-4 rounded-full"
      source={query.data?.metadata?.url}
    />
  );
};

export default Reaction;
