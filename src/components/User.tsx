import React, { FC } from 'react';
import { Typography } from '@supabase/ui';
import useUser from '../hooks/useUser';
import Avatar from './Avatar';
import { useCommentsContext } from './CommentsProvider';
import clsx from 'clsx';

interface UserProps {
  id?: string;
  showName?: boolean;
  showAvatar?: boolean;
  className?: string;
}

const User: FC<UserProps> = ({
  id,
  showName = true,
  showAvatar = true,
  className,
}) => {
  const context = useCommentsContext();
  const query = useUser({ id: id!, enabled: !!id });

  const user = query.data;

  return (
    <div className={clsx('flex items-center space-x-2', className)}>
      {showAvatar && (
        <Avatar
          className={clsx(user && 'cursor-pointer')}
          onClick={() => {
            if (user) {
              context.onUserClick?.(user);
            }
          }}
          src={user?.avatar}
        />
      )}
      {user && showName && (
        <Typography.Text>
          <span
            className="cursor-pointer"
            tabIndex={0}
            onClick={() => {
              context.onUserClick?.(user);
            }}
          >
            {user.name}
          </span>
        </Typography.Text>
      )}
    </div>
  );
};

export default User;
