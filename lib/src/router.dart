import 'package:shelf_router/shelf_router.dart';
import 'controller/agent_controller.dart';

final Router apiRouter = Router();

void apiRoutes(AgentController agentController) {
  apiRouter.get('/version', agentController.getVersion);

  apiRouter.post('/presetOpenSpecList', agentController.setPresetOpenSpecList);
  apiRouter.post('/initSession', agentController.initSession);
  apiRouter.post('/initSimple', agentController.initSimple);
  apiRouter.post('/chat', agentController.startStream);
  apiRouter.post('/chat/simple', agentController.startSimple);
  apiRouter.get('/history/summary', agentController.historySummary);
  apiRouter.get('/history/process', agentController.historyProcess);
  apiRouter.get('/history', agentController.history);
  apiRouter.get('/stop', agentController.stopSession);
  apiRouter.get('/clear', agentController.clearSession);
  apiRouter.post('/callback', agentController.callback);
  apiRouter.post('/streamCallback', agentController.streamCallback);

  apiRouter.get('/session/subscribe', agentController.subscribeSession);
}
