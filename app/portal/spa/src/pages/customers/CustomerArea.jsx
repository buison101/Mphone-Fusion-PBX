import Customers from './Customers';
import Workspaces from 'pages/workspaces/Workspaces';
import useSession from 'hooks/useSession';

export default function CustomerArea() {
  const { session } = useSession();
  return session?.identity ? <Workspaces /> : <Customers />;
}
