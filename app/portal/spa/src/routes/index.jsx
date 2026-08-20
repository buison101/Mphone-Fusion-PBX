import { createBrowserRouter } from 'react-router-dom';

// project imports
import MainRoutes from './MainRoutes';
import { BASE_PATH } from 'config';

// ==============================|| ROUTING RENDER ||============================== //
//
// The portal is served from /p/ so the router is told about the prefix, otherwise
// a refresh on a deep link would not resolve.

const router = createBrowserRouter([MainRoutes], { basename: BASE_PATH });

export default router;
