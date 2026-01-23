import 'package:shelf_router/shelf_router.dart';
import 'controller/agent_controller.dart';
import 'controller/agent_manage_controller.dart';

final Router apiRouter = Router();

void apiRoutes(
  AgentController agentController,
  AgentManageController agentManageController,
) {
  apiRouter.get('/version', agentController.getVersion);

  apiRouter.get('/agent/list', agentManageController.listAgent);
  apiRouter.get('/agent', agentManageController.getAgent);
  apiRouter.post('/agent/create', agentManageController.createAgent);
  apiRouter.post('/agent/update', agentManageController.updateAgent);
  apiRouter.get('/agent/delete', agentManageController.deleteAgent);

  apiRouter.post('/presetOpenSpec', agentController.addPresetOpenSpec);
  apiRouter.post('/initSession', agentController.initSession);
  apiRouter.post('/initSimple', agentController.initSimple);
  apiRouter.post('/chat', agentController.startStream);
  apiRouter.post('/chat/simple', agentController.startSimple);
  apiRouter.get('/history', agentController.history);
  apiRouter.get('/stop', agentController.stopSession);
  apiRouter.get('/clear', agentController.clearSession);
  apiRouter.get('/opentool-list', agentController.getOpenToolList);
  apiRouter.post('/callback', agentController.callback);
  apiRouter.post('/streamCallback', agentController.streamCallback);

  apiRouter.get('/session/list', agentController.listSessions);
  apiRouter.get('/session/subscribe', agentController.subscribeSession);
}
