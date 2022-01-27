import { SupabaseClient } from '@supabase/supabase-js';
import { Auth, Button, IconInfo, Modal, Typography } from '@supabase/ui';
import { useState, FC } from 'react';

interface AuthModalProps {
  visible: boolean;
  onClose: () => void;
  supabaseClient: SupabaseClient;
}
const AuthModal: FC<AuthModalProps> = ({
  visible,
  onClose,
  supabaseClient,
}) => {
  return (
    <Modal
      title="Please Sign In"
      //   description="Please sign in to leave a comment or reaction"
      visible={visible}
      onCancel={onClose}
      hideFooter
    >
      <div className="!-mt-4 w-full">
        <Auth view="sign_up" supabaseClient={supabaseClient} />
      </div>
    </Modal>
  );
};

export default AuthModal;
