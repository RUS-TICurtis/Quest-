-- View to join moderation actions with profiles for the audit log
CREATE OR REPLACE VIEW public.audit_log_view AS
SELECT 
    ma.id,
    ma.action,
    ma.target_type,
    ma.target_id,
    ma.target_id_int,
    ma.reason,
    ma.metadata,
    ma.created_at,
    p.username as admin_username,
    p.avatar_url as admin_avatar_url,
    p.display_name as admin_display_name
FROM 
    public.moderation_actions ma
LEFT JOIN 
    public.profiles p ON ma.actor_id = p.id
ORDER BY 
    ma.created_at DESC;

-- Grant access to admins
ALTER VIEW public.audit_log_view OWNER TO postgres;
GRANT SELECT ON public.audit_log_view TO authenticated;
GRANT SELECT ON public.audit_log_view TO service_role;
