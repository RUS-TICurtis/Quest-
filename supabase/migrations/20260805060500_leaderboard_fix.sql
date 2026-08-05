ALTER TABLE public.leaderboard
  RENAME COLUMN "score" TO "xpThisWeek";

ALTER TABLE public.leaderboard
  ADD COLUMN "initials" text DEFAULT '?',
  ADD COLUMN "archetype" text DEFAULT 'Unknown',
  ADD COLUMN "streakDays" int DEFAULT 0;

ALTER TABLE public.leaderboard
  RENAME COLUMN "avatarUrl" TO "avatar";
