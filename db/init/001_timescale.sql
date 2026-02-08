-- TimescaleDB Initialization Script
-- For 5G Health Platform - Local Development

-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Verify extension is installed
SELECT extname, extversion FROM pg_extension WHERE extname = 'timescaledb';

-- Create additional useful extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Log successful initialization
DO $$
BEGIN
    RAISE NOTICE 'TimescaleDB extension enabled successfully';
    RAISE NOTICE 'Database: % is ready for use', current_database();
END $$;

-- Note: Application services will handle their own schema migrations
-- This script only ensures the database and required extensions are ready
