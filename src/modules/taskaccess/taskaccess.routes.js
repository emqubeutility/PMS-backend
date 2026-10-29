import { SCREENS } from '../../config/menus.js';
import * as service from './taskaccess.service.js';

const tags = ['Task Master'];
const person = { type: 'object', properties: { id: { type: 'integer' }, name: { type: 'string' } } };
const access = {
  type: 'object',
  properties: {
    id: { type: 'integer' },
    name: { type: 'string' },
    username: { type: 'string' },
    roleName: { type: ['string', 'null'] },
    userIds: { type: 'array', items: { type: 'integer' }, description: 'people whose tasks / timesheets this user may see' },
  },
};

export default async function taskAccessRoutes(fastify) {
  const { db, authorize } = fastify;
  fastify.addHook('onRequest', fastify.authenticate);

  // any signed-in user: the people for the Employee filter on the Task and Timesheet lists
  fastify.get(
    '/visible-users',
    { schema: { tags, summary: 'People whose tasks / time the signed-in user can see (Employee filter)', response: { 200: { type: 'array', items: person } } } },
    (req) => service.visibleUsers(db, req.auth),
  );

  fastify.get(
    '/',
    { schema: { tags, summary: 'Task Master: every user with the people they may see', response: { 200: { type: 'array', items: access } } }, preHandler: authorize(SCREENS.TASK_MASTER, 'view') },
    () => service.listAccess(db),
  );

  fastify.put(
    '/:viewerId',
    {
      schema: {
        tags,
        summary: 'Task Master: set the people a user may see (replaces the list)',
        params: { type: 'object', required: ['viewerId'], properties: { viewerId: { type: 'integer', minimum: 1 } } },
        body: { type: 'object', additionalProperties: false, required: ['userIds'], properties: { userIds: { type: 'array', items: { type: 'integer', minimum: 1 }, maxItems: 2000 } } },
        response: { 200: access },
      },
      preHandler: authorize(SCREENS.TASK_MASTER, 'edit'),
    },
    (req) => service.saveAccess(db, req.auth, req.params.viewerId, req.body.userIds),
  );
}
