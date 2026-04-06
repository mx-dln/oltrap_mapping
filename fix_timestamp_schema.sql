-- Fix timestamp column type from INTEGER to BIGINT
-- Run this in your Supabase SQL Editor to fix the existing table

-- Step 1: Drop the existing table (this will delete all data)
DROP TABLE IF EXISTS oltraps CASCADE;

-- Step 2: Recreate the table with correct data types
CREATE TABLE IF NOT EXISTS oltraps (
    id TEXT PRIMARY KEY,
    qr_code_data TEXT NOT NULL UNIQUE,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    timestamp BIGINT NOT NULL,
    notes TEXT,
    location_name TEXT,
    status TEXT NOT NULL DEFAULT 'deployed',
    is_missing BOOLEAN NOT NULL DEFAULT FALSE,
    is_damaged BOOLEAN NOT NULL DEFAULT FALSE,
    created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
);

-- Step 3: Recreate indexes
CREATE INDEX IF NOT EXISTS idx_oltraps_qr_code_data ON oltraps(qr_code_data);
CREATE INDEX IF NOT EXISTS idx_oltraps_location_name ON oltraps(location_name);
CREATE INDEX IF NOT EXISTS idx_oltraps_status ON oltraps(status);
CREATE INDEX IF NOT EXISTS idx_oltraps_timestamp ON oltraps(timestamp);
CREATE INDEX IF NOT EXISTS idx_oltraps_created_at ON oltraps(created_at);

-- Step 4: Enable Row Level Security (RLS)
ALTER TABLE oltraps ENABLE ROW LEVEL SECURITY;

-- Step 5: Recreate policies
CREATE POLICY "Allow read access to all users" ON oltraps
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow insert access to all users" ON oltraps
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow update access to all users" ON oltraps
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Allow delete access to all users" ON oltraps
    FOR DELETE USING (auth.role() = 'authenticated');

-- Step 6: Grant permissions
GRANT ALL ON oltraps TO authenticated;
GRANT SELECT ON oltraps TO anon;

-- Step 7: Recreate statistics view
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
GRANT SELECT ON oltrap_statistics TO authenticated;
GRANT SELECT ON oltrap_statistics TO anon;

-- Step 8: Add comments
COMMENT ON TABLE oltraps IS 'Oriental Leafhopper Trap locations and data';
COMMENT ON COLUMN oltraps.id IS 'Unique identifier for the trap';
COMMENT ON COLUMN oltraps.qr_code_data IS 'QR code data from the trap';
COMMENT ON COLUMN oltraps.latitude IS 'GPS latitude coordinate';
COMMENT ON COLUMN oltraps.longitude IS 'GPS longitude coordinate';
COMMENT ON COLUMN oltraps.timestamp IS 'Original timestamp from QR scan (milliseconds since epoch)';
COMMENT ON COLUMN oltraps.notes IS 'Additional notes about the trap';
COMMENT ON COLUMN oltraps.location_name IS 'Name of the location where trap is placed';
COMMENT ON COLUMN oltraps.status IS 'Current status: deployed or harvested';
COMMENT ON COLUMN oltraps.is_missing IS 'Whether the trap is missing';
COMMENT ON COLUMN oltraps.is_damaged IS 'Whether the trap is damaged';
COMMENT ON COLUMN oltraps.created_at IS 'Timestamp when record was created in database (milliseconds since epoch)';

-- Table is now ready with correct BIGINT data types for timestamps
