import React, { createContext, FC, useContext, useMemo, useState } from 'react';
import type * as api from '../api';

interface ReplyManagerContextApi {
  replyingTo: api.Comment | null;
  setReplyingTo: (comment: api.Comment | null) => void;
}

const ReplyManagerContext = createContext<ReplyManagerContextApi | null>(null);

export const useReplyManager = () => {
  return useContext(ReplyManagerContext);
};

const ReplyManagerProvider: FC = ({ children }) => {
  const [replyingTo, setReplyingTo] = useState<api.Comment | null>(null);

  const api = useMemo(
    () => ({
      replyingTo,
      setReplyingTo,
    }),
    [replyingTo, setReplyingTo]
  );
  return (
    <ReplyManagerContext.Provider value={api}>
      {children}
    </ReplyManagerContext.Provider>
  );
};

export default ReplyManagerProvider;
