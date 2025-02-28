import 'package:lite_agent_core_dart_server/src/controller/agent_manage_controller.dart';
import 'package:shelf_router/shelf_router.dart';
import 'controller.dart';

final Router apiRouter = Router();

AgentManageController agentManageController = AgentManageController();

void apiRoutes(AgentController agentController) {
  apiRouter.get('/version', agentController.getVersion);

  apiRouter.get('/agent/list', agentManageController.listAgent);
  apiRouter.get('/agent', agentManageController.getAgent);
  apiRouter.post('/agent/create', agentManageController.createAgent);
  apiRouter.post('/agent/update', agentManageController.updateAgent);
  apiRouter.get('/agent/delete', agentManageController.deleteAgent);

  apiRouter.post('/init', agentController.initSession);
  apiRouter.post('/init/simple', agentController.initSimple);
  apiRouter.get('/chat', agentController.startSession);
  apiRouter.post('/chat/simple', agentController.startSimple);
  apiRouter.get('/history', agentController.history);
  apiRouter.get('/stop', agentController.stopSession);
  apiRouter.get('/clear', agentController.clearSession);
  apiRouter.get('/opentool-list', agentController.getOpenToolList);
}
