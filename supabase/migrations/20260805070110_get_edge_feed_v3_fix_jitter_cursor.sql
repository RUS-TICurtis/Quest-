-- Drop ALL known overloads of get_edge_feed to avoid signature conflicts
DROP FUNCTION IF EXISTS public.get_edge_feed(UUID, INT, INT, UUID, TEXT, UUID[], TEXT[]);
DROP FUNCTION IF EXISTS public.get_edge_feed(UUID, INT, INT, UUID, TEXT, UUID[], TEXT[], UUID[]);

CREATE OR REPLACE FUNCTION public.get_edge_feed(
  p_user_id             UUID,
  p_limit               INT          DEFAULT 15,
  p_cursor_rank         INT          DEFAULT 0,
  p_cursor_id           UUID         DEFAULT NULL,
  p_session_seed        TEXT         DEFAULT 'default',
  p_seen_ids            UUID[]       DEFAULT '{}',
  p_recent_genres       TEXT[]       DEFAULT '{}',
  p_local_blocked_ids   UUID[]       DEFAULT '{}'
)
RETURNS TABLE (
  id                    UUID,
  creator_id            UUID,
  title                 TEXT,
  description           TEXT,
  video_url             TEXT,
  thumbnail_url         TEXT,
  duration_seconds      INT,
  duration_ms           INT,
  view_count            INT,
  like_count            INT,
  comment_count         INT,
  share_count           INT,
  status                TEXT,
  category              TEXT,
  avg_completion_pct    NUMERIC,
  engagement_score      NUMERIC,
  mux_playback_id       TEXT,
  mux_status            TEXT,
  created_at            TIMESTAMPTZ,
  updated_at            TIMESTAMPTZ,
  deleted_at            TIMESTAMPTZ,
  creator_username      TEXT,
  creator_avatar_url    TEXT,
  tmdb_id               INT,
  tmdb_title            TEXT,
  tmdb_type             TEXT,
  liked_by_current_user BOOLEAN,
  rank_position         INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    v.id,
    v.creator_id,
    v.title,
    v.description,
    v.video_url,
    v.thumbnail_url,
    v.duration_seconds,
    COALESCE(v.duration_seconds, 0) * 1000 AS duration_ms,
    v.view_count,
    v.like_count,
    v.comment_count,
    v.share_count,
    v.status,
    CASE WHEN v.tags IS NOT NULL AND array_length(v.tags, 1) > 0
         THEN v.tags[1]
         ELSE NULL
    END AS category,
    v.avg_completion_pct,
    v.engagement_score,
    v.mux_playback_id,
    v.mux_status,
    v.created_at,
    v.updated_at,
    v.deleted_at,
    p.username   AS creator_username,
    p.avatar_url AS creator_avatar_url,
    v.tmdb_id,
    v.tmdb_title,
    v.tmdb_type,
    -- Liked state for current user
    EXISTS (
      SELECT 1 FROM public.video_reactions vr
       WHERE vr.video_id = v.id
         AND vr.user_id = p_user_id
         AND vr.reaction_type = 'heart'
    ) AS liked_by_current_user,
    -- Return computed rank_position so the frontend can build the next cursor accurately
    (
      fr.rank_position + (
        CASE
          WHEN fr.rank_position <= 50 THEN abs(hashtext(v.id::text || p_session_seed)) % 5
          WHEN fr.rank_position <= 200 THEN abs(hashtext(v.id::text || p_session_seed)) % 20
          ELSE abs(hashtext(v.id::text || p_session_seed)) % 50
        END
      )
    ) AS rank_position

  FROM public.feed_rankings fr
  INNER JOIN public.creator_videos v ON v.id = fr.video_id
  LEFT JOIN public.profiles p ON p.id = v.creator_id

  WHERE
    fr.category = 'for_you'

    -- Index-friendly rough boundary to prevent full table scans when cursor is deep
    AND fr.rank_position >= GREATEST(0, p_cursor_rank - 50)

    -- Exact Cursor pagination using the computed jittered rank
    AND (
      p_cursor_rank = 0
      OR (
        fr.rank_position + (
          CASE
            WHEN fr.rank_position <= 50 THEN abs(hashtext(v.id::text || p_session_seed)) % 5
            WHEN fr.rank_position <= 200 THEN abs(hashtext(v.id::text || p_session_seed)) % 20
            ELSE abs(hashtext(v.id::text || p_session_seed)) % 50
          END
        )
      ) > p_cursor_rank
      OR (
        (
          fr.rank_position + (
            CASE
              WHEN fr.rank_position <= 50 THEN abs(hashtext(v.id::text || p_session_seed)) % 5
              WHEN fr.rank_position <= 200 THEN abs(hashtext(v.id::text || p_session_seed)) % 20
              ELSE abs(hashtext(v.id::text || p_session_seed)) % 50
            END
          )
        ) = p_cursor_rank AND v.id > p_cursor_id
      )
    )

    -- Backend seen-video dedup
    AND (
      p_seen_ids IS NULL
      OR array_length(p_seen_ids, 1) IS NULL
      OR v.id != ALL(p_seen_ids)
    )

    -- Standard safety filters
    AND v.deleted_at IS NULL
    AND COALESCE(p.is_banned, false) = false
    AND (COALESCE(p.is_shadowbanned, false) = false OR v.creator_id = p_user_id)

    -- Block compliance
    AND NOT EXISTS (
      SELECT 1 FROM public.user_blocks ub
       WHERE (ub.blocker_id = p_user_id AND ub.blocked_id = v.creator_id)
          OR (ub.blocker_id = v.creator_id AND ub.blocked_id = p_user_id)
    )

    -- Local Block compliance (Optimistic UI filtering sent from client)
    AND (
      p_local_blocked_ids IS NULL 
      OR array_length(p_local_blocked_ids, 1) IS NULL 
      OR v.creator_id != ALL(p_local_blocked_ids)
    )

    -- Status filter
    AND (
      v.status = 'approved'
      OR (v.mux_status = 'ready' AND v.status NOT IN ('rejected', 'removed', 'disabled'))
    )

    AND (v.suppress_until IS NULL OR v.suppress_until < now())

  ORDER BY
    (
      fr.rank_position + (
        CASE
          WHEN fr.rank_position <= 50 THEN abs(hashtext(v.id::text || p_session_seed)) % 5
          WHEN fr.rank_position <= 200 THEN abs(hashtext(v.id::text || p_session_seed)) % 20
          ELSE abs(hashtext(v.id::text || p_session_seed)) % 50
        END
      )
    ) ASC,
    (CASE WHEN (
      v.tags IS NOT NULL AND array_length(v.tags, 1) > 0 AND
      v.tags[1]::text = ANY(p_recent_genres)
    ) THEN 0 ELSE 1 END) ASC,
    (CASE WHEN v.mux_playback_id IS NOT NULL AND v.mux_status = 'ready' THEN 0 ELSE 1 END) ASC,
    v.id ASC

  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Secure the RPC
REVOKE EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, UUID, TEXT, UUID[], TEXT[], UUID[]) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, UUID, TEXT, UUID[], TEXT[], UUID[]) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, UUID, TEXT, UUID[], TEXT[], UUID[]) FROM anon;

GRANT EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, UUID, TEXT, UUID[], TEXT[], UUID[]) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, UUID, TEXT, UUID[], TEXT[], UUID[]) TO postgres;
