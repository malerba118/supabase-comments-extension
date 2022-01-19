import React, { createContext, FC, useContext, useMemo, useState } from 'react';
import type * as api from '../api';

interface ReplyContextApi {
  replyingTo: api.Comment | null;
  setReplyingTo: (comment: api.Comment | null) => void;
}

const ReplyContext = createContext<ReplyContextApi | null>(null);

export const useReply = () => {
  return useContext(ReplyContext);
};

const ReplyProvider: FC = ({ children }) => {
  const [replyingTo, setReplyingTo] = useState<api.Comment | null>(null);

  const api = useMemo(
    () => ({
      replyingTo,
      setReplyingTo,
    }),
    [replyingTo, setReplyingTo]
  );
  return <ReplyContext.Provider value={api}>{children}</ReplyContext.Provider>;
};

export default ReplyProvider;
