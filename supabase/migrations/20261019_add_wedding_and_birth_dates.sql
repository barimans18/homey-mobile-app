-- ==============================================================================
-- ADD WEDDING DATE & BIRTHDAYS TO FAMILIES & PROFILES
-- ==============================================================================

ALTER TABLE public.families 
ADD COLUMN IF NOT EXISTS wedding_date date,
ADD COLUMN IF NOT EXISTS husband_birthday date,
ADD COLUMN IF NOT EXISTS wife_birthday date;

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS birth_date date;
