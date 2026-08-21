-- Migration: Fix missing user_reputation relation trigger error
-- This migration automatically scans all triggers in the public schema,
-- identifies any trigger function whose source code references the non-existent
-- "user_reputation" table, and drops the trigger and function to restore posting.

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT 
            t.tgname AS trigger_name,
            c.relname AS table_name,
            p.proname AS function_name
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        JOIN pg_proc p ON t.tgfoid = p.oid
        WHERE n.nspname = 'public'
    LOOP
        -- If the trigger function source code references "user_reputation",
        -- drop the trigger and function to prevent SQL state crashes on insert.
        IF EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = r.function_name 
              AND prosrc ILIKE '%user_reputation%'
        ) THEN
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.%I CASCADE;', r.trigger_name, r.table_name);
            EXECUTE format('DROP FUNCTION IF EXISTS public.%I() CASCADE;', r.function_name);
            RAISE NOTICE 'Dropped trigger % on table % and its function % because it referenced missing user_reputation table', 
                r.trigger_name, r.table_name, r.function_name;
        END IF;
    END LOOP;
END $$;
