-- ==============================================================================
-- MIGRATION: ADD 6-DIGIT FAMILY PIN & UPDATE POLICY
-- Kolom PIN 6 digit untuk keamanan saat pasangan bergabung (pairing)
-- ==============================================================================

ALTER TABLE public.families ADD COLUMN IF NOT EXISTS pin text NOT NULL DEFAULT '123456';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_families_pin'
    ) THEN
        ALTER TABLE public.families 
        ADD CONSTRAINT chk_families_pin CHECK (pin ~ '^[0-9]{6}$');
    END IF;
END $$;

-- Policy agar role anon dapat mengupdate data keluarga (misal: PIN & nama keluarga)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'families' AND policyname = 'Anon dapat memperbarui data keluarga'
    ) THEN
        CREATE POLICY "Anon dapat memperbarui data keluarga" 
        ON public.families 
        FOR UPDATE 
        TO anon 
        USING (true) 
        WITH CHECK (true);
    END IF;
END $$;
