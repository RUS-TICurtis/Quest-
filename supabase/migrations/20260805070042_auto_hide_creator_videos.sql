-- Migration to automatically hide highly reported videos (>= 5 reports)
CREATE OR REPLACE FUNCTION public.sync_report_count()
RETURNS TRIGGER AS $$
DECLARE
  v_report_count INT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Increment the report count on the video
    UPDATE public.creator_videos
    SET report_count = COALESCE(report_count, 0) + 1
    WHERE id = NEW.video_id
    RETURNING report_count INTO v_report_count;

    -- If the report count is >= 5, set status to 'removed' (permanent hide)
    IF v_report_count >= 5 THEN
      UPDATE public.creator_videos
      SET status = 'removed'
      WHERE id = NEW.video_id;
    -- If the report count is >= 3, set temporary suppression for 24 hours
    ELSIF v_report_count >= 3 THEN
      UPDATE public.creator_videos
      SET suppress_until = GREATEST(COALESCE(suppress_until, now()), now() + interval '24 hours')
      WHERE id = NEW.video_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
