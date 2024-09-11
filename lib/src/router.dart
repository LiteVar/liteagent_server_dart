import 'package:shelf_router/shelf_router.dart';
import 'controller.dart';

final Router apiRouter = Router();

void apiRoutes() {
  apiRouter.get('/version', agentController.getVersion);
  apiRouter.post('/init', agentController.initChat);
  apiRouter.post('/init/simple', agentController.initSimple);
  apiRouter.get('/chat', agentController.chat);
  apiRouter.post('/chat/simple', agentController.startSimple);
  apiRouter.get('/history', agentController.history);
  apiRouter.get('/stop', agentController.stopChat);
  apiRouter.get('/clear', agentController.clearChat);
}
