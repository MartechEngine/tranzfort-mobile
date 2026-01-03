-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. Users Table
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone TEXT UNIQUE NOT NULL,
    role TEXT CHECK (role IN ('SUPPLIER', 'TRUCKER', 'ADMIN')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Supplier Profiles Table
CREATE TABLE IF NOT EXISTS public.supplier_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    company_name TEXT,
    owner_name TEXT,
    address TEXT,
    city TEXT,
    verification_status TEXT DEFAULT 'PENDING' CHECK (verification_status IN ('PENDING', 'VERIFIED', 'REJECTED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Trucker Profiles Table
CREATE TABLE IF NOT EXISTS public.trucker_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    full_name TEXT,
    truck_rc_number TEXT,
    truck_type TEXT,
    wheel_count INTEGER,
    verification_status TEXT DEFAULT 'PENDING' CHECK (verification_status IN ('PENDING', 'VERIFIED', 'REJECTED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Trucks Table (for truckers with multiple vehicles)
CREATE TABLE IF NOT EXISTS public.trucks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trucker_id UUID NOT NULL REFERENCES public.trucker_profiles(id) ON DELETE CASCADE,
    rc_number TEXT UNIQUE NOT NULL,
    truck_type TEXT NOT NULL,
    wheel_count INTEGER NOT NULL,
    capacity_mt NUMERIC NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. Loads Table
CREATE TABLE IF NOT EXISTS public.loads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL REFERENCES public.supplier_profiles(id) ON DELETE CASCADE,
    pickup_location JSONB NOT NULL, -- {city, coordinates: {lat, lng}, address}
    drop_location JSONB NOT NULL, -- {city, coordinates: {lat, lng}, address}
    pickup_point GEOGRAPHY(POINT) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint((pickup_location->'coordinates'->>'lng')::float, (pickup_location->'coordinates'->>'lat')::float), 4324)::GEOGRAPHY) STORED,
    drop_point GEOGRAPHY(POINT) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint((drop_location->'coordinates'->>'lng')::float, (drop_location->'coordinates'->>'lat')::float), 4324)::GEOGRAPHY) STORED,
    material_type TEXT NOT NULL,
    weight_mt NUMERIC NOT NULL,
    required_truck_type TEXT,
    required_wheels INTEGER,
    loading_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'EXPIRED', 'CLOSED')),
    expected_rate NUMERIC,
    remarks TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS loads_pickup_point_idx ON public.loads USING GIST (pickup_point);
CREATE INDEX IF NOT EXISTS loads_drop_point_idx ON public.loads USING GIST (drop_point);

-- RPC Function for radius search
CREATE OR REPLACE FUNCTION get_loads_by_radius(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_radius_meters DOUBLE PRECISION
)
RETURNS SETOF loads AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM loads
    WHERE ST_DWithin(
        pickup_point,
        ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
        p_radius_meters
    )
    AND status = 'ACTIVE'
    ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Chats Table
CREATE TABLE IF NOT EXISTS public.chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    load_id UUID NOT NULL REFERENCES public.loads(id) ON DELETE CASCADE,
    trucker_id UUID NOT NULL REFERENCES public.trucker_profiles(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'EXPIRED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 7. Chat Messages Table
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 8. Verifications Table
CREATE TABLE IF NOT EXISTS public.verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    document_url TEXT NOT NULL,
    document_type TEXT NOT NULL, -- 'GST', 'RC', 'DL', 'VISITING_CARD'
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 9. Ads Table
CREATE TABLE IF NOT EXISTS public.ads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    image_url TEXT NOT NULL,
    target_url TEXT,
    placement TEXT NOT NULL, -- 'HOME_BANNER', 'LOAD_LIST_INLINE', 'PROFILE'
    is_active BOOLEAN DEFAULT true,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 10. Subscriptions Table
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    plan_type TEXT NOT NULL CHECK (plan_type IN ('FREE', 'PREMIUM')),
    status TEXT DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'EXPIRED', 'CANCELLED')),
    start_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 11. Reports Table
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    target_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    target_load_id UUID REFERENCES public.loads(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    details TEXT,
    status TEXT DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'INVESTIGATING', 'RESOLVED', 'DISMISSED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 12. Load Filters / Saved Routes
CREATE TABLE IF NOT EXISTS public.load_filters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    from_city TEXT,
    to_city TEXT,
    truck_type TEXT,
    is_alert_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 13. Audit Logs
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES public.users(id),
    action TEXT NOT NULL,
    target_type TEXT NOT NULL, -- 'USER', 'LOAD', 'VERIFICATION', 'AD'
    target_id UUID NOT NULL,
    old_value JSONB,
    new_value JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Realtime for relevant tables
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE loads;
ALTER PUBLICATION supabase_realtime ADD TABLE chats;
ALTER PUBLICATION supabase_realtime ADD TABLE verifications;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications; -- (Will create this table if missing)

-- 14. Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    fcm_status TEXT DEFAULT 'PENDING' CHECK (fcm_status IN ('PENDING', 'SENT', 'FAILED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trucker_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trucks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.load_filters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 1. Users policies
CREATE POLICY "Users can view their own record" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can view all users" ON public.users FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'ADMIN'));

-- 2. Supplier Profiles policies
CREATE POLICY "Public can view supplier profiles" ON public.supplier_profiles FOR SELECT USING (true);
CREATE POLICY "Suppliers can update their own profile" ON public.supplier_profiles FOR UPDATE USING (auth.uid() = user_id);

-- 3. Trucker Profiles policies
CREATE POLICY "Truckers can view/update their own profile" ON public.trucker_profiles USING (auth.uid() = user_id);
CREATE POLICY "Suppliers can view trucker profiles they are chatting with" ON public.trucker_profiles FOR SELECT 
USING (EXISTS (SELECT 1 FROM public.chats c JOIN public.loads l ON c.load_id = l.id WHERE c.trucker_id = public.trucker_profiles.id AND l.supplier_id = (SELECT id FROM public.supplier_profiles WHERE user_id = auth.uid())));

-- 4. Loads policies
CREATE POLICY "Anyone can view active loads" ON public.loads FOR SELECT USING (status = 'ACTIVE');
CREATE POLICY "Suppliers can manage their own loads" ON public.loads USING (EXISTS (SELECT 1 FROM public.supplier_profiles WHERE id = loads.supplier_id AND user_id = auth.uid()));

-- 5. Chats policies
CREATE POLICY "Participants can view their chats" ON public.chats FOR SELECT 
USING (
    trucker_id = (SELECT id FROM public.trucker_profiles WHERE user_id = auth.uid()) OR 
    load_id IN (SELECT id FROM public.loads WHERE supplier_id = (SELECT id FROM public.supplier_profiles WHERE user_id = auth.uid()))
);

-- 6. Chat Messages policies
CREATE POLICY "Participants can view/send messages" ON public.chat_messages
USING (EXISTS (SELECT 1 FROM public.chats WHERE id = chat_messages.chat_id AND 
    (trucker_id = (SELECT id FROM public.trucker_profiles WHERE user_id = auth.uid()) OR 
     load_id IN (SELECT id FROM public.loads WHERE supplier_id = (SELECT id FROM public.supplier_profiles WHERE user_id = auth.uid())))));

-- 7. Notifications policies
CREATE POLICY "Users can manage their own notifications" ON public.notifications USING (user_id = auth.uid());

-- 8. Admin policies
CREATE POLICY "Admins have full access to everything" ON public.users FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'ADMIN'));
-- (Simplified for brevity, usually you'd repeat for each table or use a helper function)
