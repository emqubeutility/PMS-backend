// Screen keys used by the RBAC checks. They are the `menus.url` values (React routes),
// so the same key drives the API permission check and the frontend route guard.
export const SCREENS = Object.freeze({
  USERS: '/administration/users',
  ROLES: '/administration/roles',
  TEAMS: '/administration/teams',
  PARAMETERS: '/administration/parameters',
  SITES: '/administration/sites',
  RESOURCE_GRADES: '/administration/resource-grades',
  TASK_GROUPS: '/administration/task-groups',
  TASK_TYPES: '/administration/task-groups', // the Task Types tab of "Task Groups & Types" – same menu and permissions
  PROJECT_DIVISIONS: '/administration/project-divisions',
  PROJECT_STAGES: '/administration/project-stages',
  TASK_MASTER: '/administration/task-master', // who can see whose tasks / timesheets
  CUSTOMERS: '/customers',
  PROJECTS: '/projects',
  TASK_CATEGORIES: '/administration/task-groups', // the Task Categories tab of "Task Groups & Types" – same menu and permissions
  TASKS: '/tasks',
  TASK_135: '/task-135',
  TIMESHEET: '/timesheet',
});

export const ACTIONS = Object.freeze(['view', 'create', 'edit', 'delete', 'approve', 'export']);
