-- Drop existing table if it exists to ensure clean slate
DROP TABLE IF EXISTS case_citizen_assignment CASCADE;

-- Create new case-citizen assignment table
CREATE TABLE IF NOT EXISTS case_citizen_assignment (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    case_manager_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    citizen_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    assignment_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (assignment_status IN ('pending', 'accepted', 'rejected', 'active')),
    request_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE,
    response_message TEXT,
    assigned_at TIMESTAMP WITH TIME ZONE,
    
    -- Ensure unique assignments between case manager and citizen
    UNIQUE(case_manager_id, citizen_id)
);

-- Drop existing indexes if they exist to avoid conflicts
DROP INDEX IF EXISTS idx_case_citizen_assignment_case_manager;
DROP INDEX IF EXISTS idx_case_citizen_assignment_citizen;
DROP INDEX IF EXISTS idx_case_citizen_assignment_status;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_case_manager ON case_citizen_assignment(case_manager_id);
CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_citizen ON case_citizen_assignment(citizen_id);
CREATE INDEX IF NOT EXISTS idx_case_citizen_assignment_status ON case_citizen_assignment(assignment_status);

-- Enable Row Level Security
ALTER TABLE case_citizen_assignment ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own assignments" ON case_citizen_assignment;
DROP POLICY IF EXISTS "Case managers can create assignments" ON case_citizen_assignment;
DROP POLICY IF EXISTS "Case managers can update their own assignments" ON case_citizen_assignment;
DROP POLICY IF EXISTS "Citizens can respond to assignments" ON case_citizen_assignment;
DROP POLICY IF EXISTS "Case managers can delete their own assignments" ON case_citizen_assignment;

-- RLS Policies - More permissive to prevent login issues
-- Allow users to view assignments where they are either case manager or citizen
CREATE POLICY "Users can view their own assignments" ON case_citizen_assignment
    FOR SELECT USING (
        auth.uid() = case_manager_id OR 
        auth.uid() = citizen_id
    );

-- Allow case managers to create assignments
CREATE POLICY "Case managers can create assignments" ON case_citizen_assignment
    FOR INSERT WITH CHECK (auth.uid() = case_manager_id);

-- Allow case managers to update their own assignments (e.g., cancel)
CREATE POLICY "Case managers can update their own assignments" ON case_citizen_assignment
    FOR UPDATE USING (auth.uid() = case_manager_id);

-- Allow citizens to update assignments made to them (accept/reject)
CREATE POLICY "Citizens can respond to assignments" ON case_citizen_assignment
    FOR UPDATE USING (auth.uid() = citizen_id);

-- Allow case managers to delete their own assignments
CREATE POLICY "Case managers can delete their own assignments" ON case_citizen_assignment
    FOR DELETE USING (auth.uid() = case_manager_id);

-- Function to update updated_at timestamp
DROP FUNCTION IF EXISTS update_case_citizen_assignment_updated_at() CASCADE;
CREATE OR REPLACE FUNCTION update_case_citizen_assignment_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists to avoid conflicts
DROP TRIGGER IF EXISTS update_case_citizen_assignment_updated_at ON case_citizen_assignment;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_case_citizen_assignment_updated_at
    BEFORE UPDATE ON case_citizen_assignment
    FOR EACH ROW
    EXECUTE FUNCTION update_case_citizen_assignment_updated_at();

-- Insert some sample data for testing (optional)
-- INSERT INTO case_citizen_assignment (case_manager_id, citizen_id, assignment_status, request_message)
-- VALUES 
--     ('case-manager-uuid-1', 'citizen-uuid-1', 'pending', 'I would like to work with you on your case.'),
--     ('case-manager-uuid-2', 'citizen-uuid-2', 'accepted', 'Looking forward to working together.'),
--     ('case-manager-uuid-3', 'citizen-uuid-3', 'rejected', 'Thank you for the offer, but I prefer to work with someone else.');
