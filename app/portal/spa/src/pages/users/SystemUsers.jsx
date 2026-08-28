import { FormattedMessage } from 'react-intl';

import ContentState from 'components/states/ContentState';
import useSession from 'hooks/useSession';
import Users from './Users';

export default function SystemUsers() {
  const { session } = useSession();
  if (!session?.user_management?.superadmin) {
    return <ContentState state="forbidden" title={<FormattedMessage id="users.systemForbidden" />} />;
  }
  return <Users titleId="users.systemTitle" />;
}
