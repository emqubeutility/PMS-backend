import { can } from '../auth/auth-context.js';
import { ACTIONS } from '../../config/menus.js';

/**
 * Menus as a tree: modules (parent_id null) with their screens. Hidden screens (is_visible = false, e.g. 1-3-5,
 * a tab on the Task page) are left out of the sidebar but kept for the role permissions (includeHidden).
 */
export async function getMenuTree(db, { includeHidden = false } = {}) {
  const { rows } = await db.query(
    `SELECT id, name, parent_id, url, icon, display_order, actions
       FROM menus
      WHERE is_visible OR ($1::boolean AND parent_id IS NOT NULL)
      ORDER BY display_order, name`,
    [includeHidden],
  );
  const modules = rows.filter((m) => m.parent_id === null).map((m) => ({ ...toDto(m), children: [] }));
  const byId = new Map(modules.map((m) => [m.id, m]));
  for (const m of rows) {
    if (m.parent_id !== null) byId.get(m.parent_id)?.children.push(toDto(m));
  }
  return modules;
}

/** The sidebar for one user: only screens the role can view; empty modules are dropped. */
export async function getUserMenus(db, auth) {
  const tree = await getMenuTree(db);
  return tree
    .map((mod) => ({ ...mod, children: mod.children.filter((c) => c.url && can(auth, c.url, 'view')) }))
    .filter((mod) => mod.children.length > 0);
}

/** Effective permission flags for every screen (Super Admin gets every action the screen supports). */
export async function getUserPermissions(db, auth) {
  const { rows } = await db.query(`SELECT url, actions FROM menus WHERE url IS NOT NULL`);
  const out = {};
  for (const { url, actions } of rows) {
    out[url] = Object.fromEntries(ACTIONS.map((a) => [a, actions.includes(a) && can(auth, url, a)]));
  }
  return out;
}

function toDto(m) {
  return { id: m.id, name: m.name, url: m.url, icon: m.icon, displayOrder: m.display_order, actions: m.actions };
}
