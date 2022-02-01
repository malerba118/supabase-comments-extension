import React, { ComponentProps, FC, useEffect } from 'react';
import { Modal } from '@supabase/ui';
import Auth from './Auth';
import { useSupabaseClient } from './CommentsProvider';
import { useLatestRef } from '../hooks/useLatestRef';
import { Session } from '@supabase/gotrue-js';

export interface AuthModalProps
  extends Omit<ComponentProps<typeof Auth>, 'supabaseClient'> {
  visible: boolean;
  onClose?: () => void;
  onAuthenticate?: (session: Session) => void;
}

const AuthModal: FC<AuthModalProps> = ({
  visible,
  onAuthenticate,
  onClose,
  view = 'sign_in',
  ...otherProps
}) => {
  const supabase = useSupabaseClient();
  const onAuthenticateRef = useLatestRef(onAuthenticate);
  useEffect(() => {
    const subscription = supabase.auth.onAuthStateChange((ev, session) => {
      if (ev === 'SIGNED_IN' && session) {
        onAuthenticateRef.current?.(session);
      }
    });
    return () => {
      subscription.data?.unsubscribe();
    };
  }, [supabase]);

  return (
    <Modal
      title="Please Sign In"
      //   description="Please sign in to leave a comment or reaction"
      visible={visible}
      onCancel={onClose}
      hideFooter
      size="medium"
    >
      <div className="!-mt-4 w-full">
        <Auth {...otherProps} view={view} supabaseClient={supabase} />
      </div>
    </Modal>
  );
};

export default AuthModal;
