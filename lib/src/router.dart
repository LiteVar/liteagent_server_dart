import 'package:shelf_router/shelf_router.dart';
import 'controller.dart';

final Router apiRouter = Router();

void apiRoutes(AgentController agentController) {
  apiRouter.get('/version', agentController.getVersion);
  apiRouter.post('/init', agentController.initSession);
  apiRouter.post('/init/simple', agentController.initSimple);
  apiRouter.get('/chat', agentController.startSession);
  apiRouter.post('/chat/simple', agentController.startSimple);
  apiRouter.get('/history', agentController.history);
  apiRouter.get('/stop', agentController.stopSession);
  apiRouter.get('/clear', agentController.clearSession);
}
