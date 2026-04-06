-- Fix RLS policies to allow anonymous access
-- Run this in your Supabase SQL Editor to fix RLS issues

-- Step 1: Drop existing policies
DROP POLICY IF EXISTS "Allow read access to all users" ON oltraps;
DROP POLICY IF EXISTS "Allow insert access to all users" ON oltraps;
DROP POLICY IF EXISTS "Allow update access to all users" ON oltraps;
DROP POLICY IF EXISTS "Allow delete access to all users" ON oltraps;

-- Step 2: Create new policies that allow anonymous access
CREATE POLICY "Allow read access to all users" ON oltraps
    FOR SELECT USING (true);

CREATE POLICY "Allow insert access to all users" ON oltraps
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow update access to all users" ON oltraps
    FOR UPDATE USING (true);

CREATE POLICY "Allow delete access to all users" ON oltraps
    FOR DELETE USING (true);

-- Step 3: Grant permissions to anonymous users
GRANT ALL ON oltraps TO anon;
GRANT SELECT ON oltraps TO authenticated;

-- Step 4: Update statistics view permissions
DROP VIEW IF EXISTS oltrap_statistics;
CREATE OR REPLACE VIEW oltrap_statistics AS
SELECT 
    COUNT(*) as total_traps,
    COUNT(CASE WHEN status = 'deployed' THEN 1 END) as deployed_traps,
    COUNT(CASE WHEN status = 'harvested' THEN 1 END) as harvested_traps,
    COUNT(CASE WHEN is_missing = TRUE THEN 1 END) as missing_traps,
    COUNT(CASE WHEN is_damaged = TRUE THEN 1 END) as damaged_traps,
    COUNT(DISTINCT location_name) as unique_locations
FROM oltraps;

-- Grant permissions on the view
GRANT SELECT ON oltrap_statistics TO anon;
GRANT SELECT ON oltrap_statistics TO authenticated;

-- RLS policies are now updated to allow anonymous access
-- This will fix the "new row violates row-level security policy" error
