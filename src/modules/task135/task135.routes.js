import { SCREENS } from '../../config/menus.js';
import * as service from './task135.service.js';

const tags = ['1-3-5'];
const idParams = { type: 'object', required: ['id'], properties: { id: { type: 'integer', minimum: 1 } } };
const date = { type: 'string', format: 'date' };
const item = {
  type: 'object',
  properties: {
    id: { type: 'integer' },
    date: { type: 'string' },
    position: { type: 'integer' },
    size: { type: 'string', enum: ['big', 'medium', 'small'] },
    kind: { type: 'string', enum: ['task', 'subtask', 'note'] },
    taskId: { type: ['integer', 'null'] },
    subtaskId: { type: ['integer', 'null'] },
    linkTaskId: { type: ['integer', 'null'], description: 'task page to open (the parent task for a subtask)' },
    parentTaskName: { type: ['string', 'null'] },
    subtaskDue: { type: ['string', 'null'] },
    title: { type: 'string' },
    minutes: { type: 'integer' },
    isDone: { type: 'boolean' },
    doneAt: { type: ['string', 'null'], format: 'date-time' },
    taskStatus: { type: ['string', 'null'] },
    taskPriority: { type: ['string', 'null'] },
    projectId: { type: ['integer', 'null'] },
    categoryId: { type: ['integer', 'null'] },
    categoryName: { type: ['string', 'null'] },
    addedByName: { type: ['string', 'null'] },
    userName: { type: ['string', 'null'] },
    projectCode: { type: ['string', 'null'] },
    projectTitle: { type: ['string', 'null'] },
  },
};
const day = {
  type: 'object',
  properties: { date: { type: 'string' }, today: { type: 'string' }, slots: { type: 'integer' }, items: { type: 'array', items: item } },
};

export default async function task135Routes(fastify) {
  const { db, authorize } = fastify;
  fastify.addHook('onRequest', fastify.authenticate);
  const can = (action) => authorize(SCREENS.TASK_135, action);

  fastify.get(
    '/',
    { schema: { tags, summary: "The signed-in user's 1-3-5 of a day (today by default)", querystring: { type: 'object', properties: { date } }, response: { 200: day } }, preHandler: can('view') },
    (req) => service.listDay(db, req.auth, req.query.date),
  );

  fastify.get(
    '/subtasks',
    {
      schema: {
        tags,
        summary: 'Picker: open subtasks assigned to me',
        querystring: { type: 'object', properties: { search: { type: 'string', maxLength: 200 } } },
        response: {
          200: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                id: { type: 'integer' },
                title: { type: 'string' },
                dueDate: { type: ['string', 'null'] },
                taskId: { type: 'integer' },
                taskName: { type: 'string' },
                priority: { type: ['string', 'null'] },
                projectCode: { type: ['string', 'null'] },
                projectTitle: { type: ['string', 'null'] },
              },
            },
          },
        },
      },
      preHandler: can('view'),
    },
    (req) => service.mySubtasks(db, req.auth, req.query.search),
  );

  fastify.post(
    '/',
    {
      schema: {
        tags,
        summary: 'Add a task, a subtask (assigned to you) or a free text to a day (next free slot)',
        body: {
          type: 'object',
          additionalProperties: false,
          properties: { date, taskId: { type: 'integer', minimum: 1 }, subtaskId: { type: 'integer', minimum: 1 }, title: { type: 'string', maxLength: 300 } },
        },
        response: { 201: item },
      },
      preHandler: can('create'),
    },
    async (req, reply) => reply.status(201).send(await service.addItem(db, req.auth, req.body)),
  );

  fastify.put(
    '/reorder',
    {
      schema: {
        tags,
        summary: 'New order of a day (ids, big first)',
        body: { type: 'object', required: ['date', 'ids'], additionalProperties: false, properties: { date, ids: { type: 'array', items: { type: 'integer' }, maxItems: 9 } } },
        response: { 200: day },
      },
      preHandler: can('edit'),
    },
    (req) => service.reorderDay(db, req.auth, req.body),
  );

  fastify.put(
    '/:id',
    {
      schema: {
        tags,
        summary: 'Rename, set the time spent or tick done (a task is not changed; a subtask is ticked too)',
        params: idParams,
        body: {
          type: 'object',
          additionalProperties: false,
          minProperties: 1,
          properties: { title: { type: 'string', minLength: 1, maxLength: 300 }, minutes: { type: 'integer', minimum: 0, maximum: 1440 }, isDone: { type: 'boolean' } },
        },
        response: { 200: item },
      },
      preHandler: can('edit'),
    },
    (req) => service.updateItem(db, req.auth, req.params.id, req.body),
  );

  fastify.post(
    '/:id/move',
    {
      schema: {
        tags,
        summary: 'Move or copy an item to another day',
        params: idParams,
        body: { type: 'object', required: ['date', 'mode'], additionalProperties: false, properties: { date, mode: { type: 'string', enum: ['move', 'copy'] } } },
        response: { 200: item },
      },
      preHandler: can('edit'),
    },
    (req) => service.moveItem(db, req.auth, req.params.id, req.body),
  );

  fastify.delete('/:id', { schema: { tags, summary: 'Remove an item from the planner', params: idParams, response: { 204: { type: 'null' } } }, preHandler: can('delete') }, async (req, reply) => {
    await service.removeItem(db, req.auth, req.params.id);
    return reply.status(204).send();
  });
}
