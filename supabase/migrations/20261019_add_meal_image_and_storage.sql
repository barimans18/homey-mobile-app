-- ==============================================================================
-- MIGRATION: ADD IMAGE_URL TO MEAL_PLANS & STORAGE BUCKET 'MEALS'
-- ==============================================================================

ALTER TABLE public.meal_plans ADD COLUMN IF NOT EXISTS image_url text;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('meals', 'meals', true) 
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'Public Access Meals') THEN
        CREATE POLICY "Public Access Meals" ON storage.objects FOR SELECT TO public USING (bucket_id = 'meals');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'Allow Upload Meals') THEN
        CREATE POLICY "Allow Upload Meals" ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'meals');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'Allow Update Meals') THEN
        CREATE POLICY "Allow Update Meals" ON storage.objects FOR UPDATE TO public USING (bucket_id = 'meals');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'Allow Delete Meals') THEN
        CREATE POLICY "Allow Delete Meals" ON storage.objects FOR DELETE TO public USING (bucket_id = 'meals');
    END IF;
END $$;
