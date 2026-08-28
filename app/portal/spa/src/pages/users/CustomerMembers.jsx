import { FormattedMessage } from 'react-intl';

import ContentState from 'components/states/ContentState';
import useSession from 'hooks/useSession';
import Users from './Users';

export default function CustomerMembers() {
  const { session } = useSession();
  if (!session?.identity || !session?.workspace?.active) {
    return <ContentState state="forbidden" title={<FormattedMessage id="users.membersForbidden" />} />;
  }
  return <Users titleId="users.membersTitle" assignmentManagement={false} />;
}
