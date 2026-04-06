-- OLTrap Mapping Database Schema for Supabase
-- Run this SQL in your Supabase SQL Editor

-- Create oltraps table
CREATE TABLE IF NOT EXISTS oltraps (
    id TEXT PRIMARY KEY,
    qr_code_data TEXT NOT NULL UNIQUE,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    timestamp INTEGER NOT NULL,
    notes TEXT,
    location_name TEXT,
    status TEXT NOT NULL DEFAULT 'deployed',
    is_missing BOOLEAN NOT NULL DEFAULT FALSE,
    is_damaged BOOLEAN NOT NULL DEFAULT FALSE,
    created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_oltraps_qr_code_data ON oltraps(qr_code_data);
CREATE INDEX IF NOT EXISTS idx_oltraps_location_name ON oltraps(location_name);
CREATE INDEX IF NOT EXISTS idx_oltraps_status ON oltraps(status);
CREATE INDEX IF NOT EXISTS idx_oltraps_timestamp ON oltraps(timestamp);
CREATE INDEX IF NOT EXISTS idx_oltraps_created_at ON oltraps(created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE oltraps ENABLE ROW LEVEL SECURITY;

-- Create policy for read access (allow all authenticated users to read)
CREATE POLICY "Allow read access to all users" ON oltraps
    FOR SELECT USING (auth.role() = 'authenticated');

-- Create policy for insert access (allow all authenticated users to insert)
CREATE POLICY "Allow insert access to all users" ON oltraps
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Create policy for update access (allow users to update their own records)
CREATE POLICY "Allow update access to all users" ON oltraps
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Create policy for delete access (allow users to delete their own records)
CREATE POLICY "Allow delete access to all users" ON oltraps
    FOR DELETE USING (auth.role() = 'authenticated');

-- Optional: Create a function to automatically update created_at
CREATE OR REPLACE FUNCTION update_created_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_at = (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Optional: Create trigger to automatically update created_at on insert
CREATE TRIGGER set_created_at
    BEFORE INSERT ON oltraps
    FOR EACH ROW
    EXECUTE FUNCTION update_created_at();

-- Grant permissions to authenticated users
GRANT ALL ON oltraps TO authenticated;
GRANT SELECT ON oltraps TO anon;

-- Create a view for statistics (optional)
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

-- Sample data (optional - for testing)
-- INSERT INTO oltraps (id, qr_code_data, latitude, longitude, timestamp, notes, location_name, status, is_missing, is_damaged)
-- VALUES 
-- ('sample_1', 'IOT:IOLT-000001', 16.71955, 121.692395, 1714332675627, 'Sample trap 1', 'Test Location', 'deployed', FALSE, FALSE),
-- ('sample_2', 'IOT:IOLT-000002', 16.72000, 121.69300, 1714332675628, 'Sample trap 2', 'Test Location', 'harvested', FALSE, TRUE);

COMMENT ON TABLE oltraps IS 'Oriental Leafhopper Trap locations and data';
COMMENT ON COLUMN oltraps.id IS 'Unique identifier for the trap';
COMMENT ON COLUMN oltraps.qr_code_data IS 'QR code data from the trap';
COMMENT ON COLUMN oltraps.latitude IS 'GPS latitude coordinate';
COMMENT ON COLUMN oltraps.longitude IS 'GPS longitude coordinate';
COMMENT ON COLUMN oltraps.timestamp IS 'Original timestamp from QR scan';
COMMENT ON COLUMN oltraps.notes IS 'Additional notes about the trap';
COMMENT ON COLUMN oltraps.location_name IS 'Name of the location where trap is placed';
COMMENT ON COLUMN oltraps.status IS 'Current status: deployed or harvested';
COMMENT ON COLUMN oltraps.is_missing IS 'Whether the trap is missing';
COMMENT ON COLUMN oltraps.is_damaged IS 'Whether the trap is damaged';
COMMENT ON COLUMN oltraps.created_at IS 'Timestamp when record was created in database';
