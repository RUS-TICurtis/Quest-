-- Add mux_asset_id to stories table
ALTER TABLE public.stories
ADD COLUMN "mux_asset_id" text;
