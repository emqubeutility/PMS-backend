import { SCREENS } from '../../config/menus.js';
import * as service from './projects.service.js';
import * as schemas from './projects.schemas.js';

export default async function projectsRoutes(fastify) {
  const { db, authorize } = fastify;
  fastify.addHook('onRequest', fastify.authenticate);

  fastify.get('/', { schema: schemas.listProjectsSchema, preHandler: authorize(SCREENS.PROJECTS, 'view') }, (req) =>
    service.listProjects(db, req.auth, req.query),
  );

  fastify.get('/summary', { schema: schemas.summarySchema, preHandler: authorize(SCREENS.PROJECTS, 'view') }, (req) =>
    service.projectSummary(db, req.auth),
  );

  fastify.get('/:id', { schema: schemas.getProjectSchema, preHandler: authorize(SCREENS.PROJECTS, 'view') }, (req) =>
    service.getProject(db, req.auth, req.params.id),
  );

  fastify.get('/:id/activity', { schema: schemas.activitySchema, preHandler: authorize(SCREENS.PROJECTS, 'view') }, (req) =>
    service.projectActivity(db, req.auth, req.params.id),
  );

  fastify.get(
    '/:id/members/:userId/removable',
    {
      schema: {
        tags: ['Projects'],
        summary: 'Users tab: can this member be removed (no time logged, no tasks)?',
        params: { type: 'object', required: ['id', 'userId'], properties: { id: { type: 'integer', minimum: 1 }, userId: { type: 'integer', minimum: 1 } } },
        response: { 200: { type: 'object', properties: { userId: { type: 'integer' }, canRemove: { type: 'boolean' }, reason: { type: ['string', 'null'] } } } },
      },
      preHandler: authorize(SCREENS.PROJECTS, 'edit'),
    },
    (req) => service.memberRemovable(db, req.auth, req.params.id, req.params.userId),
  );

  fastify.get('/:id/tasks', { schema: schemas.tasksSchema, preHandler: authorize(SCREENS.PROJECTS, 'view') }, (req) =>
    service.projectTasks(db, req.auth, req.params.id),
  );

  fastify.get('/:id/reviews', { schema: schemas.reviewsSchema, preHandler: authorize(SCREENS.PROJECTS, 'view') }, (req) =>
    service.projectReviews(db, req.auth, req.params.id),
  );

  fastify.post(
    '/:id/reviews',
    { schema: schemas.addReviewSchema, preHandler: authorize(SCREENS.PROJECTS, 'edit') },
    async (req, reply) => reply.status(201).send(await service.addReview(db, req.auth, req.params.id, req.body)),
  );

  fastify.post(
    '/',
    { schema: schemas.createProjectSchema, preHandler: authorize(SCREENS.PROJECTS, 'create') },
    async (req, reply) => reply.status(201).send(await service.createProject(db, req.auth, req.body)),
  );

  fastify.put('/:id/commercial', { schema: schemas.updateCommercialSchema, preHandler: authorize(SCREENS.PROJECTS, 'edit') }, (req) =>
    service.updateCommercial(db, req.auth, req.params.id, req.body),
  );

  fastify.put('/:id', { schema: schemas.updateProjectSchema, preHandler: authorize(SCREENS.PROJECTS, 'edit') }, (req) =>
    service.updateProject(db, req.auth, req.params.id, req.body),
  );

  fastify.delete(
    '/:id',
    { schema: schemas.deleteProjectSchema, preHandler: authorize(SCREENS.PROJECTS, 'delete') },
    async (req, reply) => {
      await service.deleteProject(db, req.auth, req.params.id);
      return reply.status(204).send();
    },
  );
}
