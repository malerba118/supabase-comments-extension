import { Dropdown, Typography } from "@supabase/ui";
import { FC, useState } from "react";
import useReactions from "../hooks/useReactions";
import Reaction from "./Reaction";

interface ReactionSelectorProps {
  activeReactions: Set<string>;
  toggleReaction: (reactionType: string) => void;
}

const ReactionSelector: FC<ReactionSelectorProps> = ({
  activeReactions,
  toggleReaction,
}) => {
  const reactions = useReactions();
  return (
    <Dropdown
      overlay={reactions.data?.map((reaction) => (
        <Dropdown.Item
          key={reaction.type}
          onClick={() => {
            toggleReaction(reaction.type);
          }}
          icon={
            <Reaction
              isActive={activeReactions.has(reaction.type)}
              type={reaction.type}
            />
          }
        >
          <Typography.Text>{reaction.metadata.label}</Typography.Text>
        </Dropdown.Item>
      ))}
    >
      <div className="flex space-x-1 p-0.5 bg-black bg-opacity-5 rounded-full">
        <div className="h-5 w-5 rounded-full bg-black bg-opacity-5 text-xs grid items-center justify-center">
          <span>+</span>
        </div>
      </div>
    </Dropdown>
  );
};

export default ReactionSelector;
