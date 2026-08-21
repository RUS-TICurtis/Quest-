-- Add missing report_types that the Flutter app uses
-- The reports.target_type column FKs to this table,
-- so inserting 'user', 'trailer', or 'community' without these rows will violate the FK.
INSERT INTO public.report_types (value) VALUES
  ('user'),
  ('trailer'),
  ('community')
ON CONFLICT (value) DO NOTHING;
