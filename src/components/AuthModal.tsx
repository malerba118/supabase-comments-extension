import React, { ComponentProps, FC, useEffect } from 'react';
import { Modal } from '@supabase/ui';
import Auth from './Auth';
import { useSupabaseClient } from './CommentsProvider';
import { useLatestRef } from '../hooks/useLatestRef';
import { Session } from '@supabase/gotrue-js';
import clsx from 'clsx';

export interface AuthModalProps
  extends Omit<ComponentProps<typeof Auth>, 'supabaseClient'> {
  visible: boolean;
  onClose?: () => void;
  onAuthenticate?: (session: Session) => void;
  title?: string;
  description?: string;
}

const AuthModal: FC<AuthModalProps> = ({
  visible,
  onAuthenticate,
  onClose,
  view = 'sign_in',
  title = 'Please Sign In',
  description,
  className,
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
      title={title}
      description={description}
      visible={visible}
      onCancel={onClose}
      hideFooter
      size="medium"
      className={clsx(' min-w-[300px]', className)}
    >
      <div
        className={clsx(
          'w-full',
          otherProps.providers && otherProps.providers?.length > 0
            ? null
            : '!-mt-4'
        )}
      >
        <Auth {...otherProps} view={view} supabaseClient={supabase} />
      </div>
    </Modal>
  );
};

export default AuthModal;
