import React, { FC } from 'react';
import { Typography } from '@supabase/ui';
import useUser from '../hooks/useUser';
import Avatar from './Avatar';
import { useCommentsContext } from './CommentsProvider';
import clsx from 'clsx';

export interface UserProps {
  id?: string;
  size?: 'sm' | 'lg';
  showName?: boolean;
  showAvatar?: boolean;
  propagateClick?: boolean;
  className?: string;
}

const User: FC<UserProps> = ({
  id,
  size = 'lg',
  showName = true,
  showAvatar = true,
  propagateClick = true,
  className,
}) => {
  const context = useCommentsContext();
  const query = useUser({ id: id! }, { enabled: !!id });

  const user = query.data;

  return (
    <div className={clsx('flex items-center space-x-2', className)}>
      {showAvatar && (
        <Avatar
          key={user?.avatar}
          className={clsx(user && 'cursor-pointer')}
          onClick={() => {
            if (user && propagateClick) {
              context.onUserClick?.(user);
            }
          }}
          src={user?.avatar}
          size={size}
        />
      )}
      {user && showName && (
        <Typography.Text>
          <span
            className="cursor-pointer"
            tabIndex={0}
            onClick={() => {
              if (propagateClick) {
                context.onUserClick?.(user);
              }
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
