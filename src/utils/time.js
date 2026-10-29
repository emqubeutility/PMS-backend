// The signed-in user's time zone (users.time_zone, IANA name) decides what "today" and
// "this week" mean in summaries and checks – not the database server's clock.

const DEFAULT_ZONE = 'Asia/Kolkata';

/** A valid IANA zone name, or the default. */
export function safeZone(tz) {
  if (tz && /^[A-Za-z0-9_/+-]+$/.test(tz)) {
    try {
      new Intl.DateTimeFormat('en-US', { timeZone: tz });
      return tz;
    } catch {
      // unknown zone – fall through
    }
  }
  return DEFAULT_ZONE;
}

/** Today in the zone as 'YYYY-MM-DD'. */
export const todayIn = (tz) =>
  new Intl.DateTimeFormat('en-CA', { timeZone: safeZone(tz), year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());

/** The date of a moment (ISO string / Date) in the zone as 'YYYY-MM-DD'. */
export const dateIn = (when, tz) =>
  new Intl.DateTimeFormat('en-CA', { timeZone: safeZone(tz), year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date(when));

/**
 * SQL for the user's today / zone, e.g. '2026-10-23'::date and 'Asia/Dubai'.
 * Both are generated here (date) or checked by safeZone (zone), never raw user input.
 */
export const sqlToday = (auth) => `'${todayIn(auth?.timeZone)}'::date`;
export const sqlZone = (auth) => `'${safeZone(auth?.timeZone)}'`;
