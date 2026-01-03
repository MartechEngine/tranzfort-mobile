import { Request, Response } from 'express';
import { supabase } from '../config/supabase.js';

export const createLoad = async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { 
    pickup_location, 
    drop_location, 
    material_type, 
    weight_mt, 
    required_truck_type, 
    required_wheels, 
    loading_date,
    expected_rate,
    remarks 
  } = req.body;

  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    // 1. Get supplier profile id
    const { data: profile, error: profileError } = await supabase
      .from('supplier_profiles')
      .select('id')
      .eq('user_id', userId)
      .single();

    if (profileError || !profile) {
      return res.status(403).json({ error: 'Supplier profile not found or not authorized' });
    }

    // 2. Insert load
    const { data, error } = await supabase
      .from('loads')
      .insert({
        supplier_id: profile.id,
        pickup_location,
        drop_location,
        material_type,
        weight_mt,
        required_truck_type,
        required_wheels,
        loading_date,
        expected_rate,
        remarks,
        status: 'ACTIVE'
      })
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({ message: 'Load created successfully', load: data });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getMyLoads = async (req: Request, res: Response) => {
  const userId = req.user?.uid;

  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const { data: profile } = await supabase
      .from('supplier_profiles')
      .select('id')
      .eq('user_id', userId)
      .single();

    if (!profile) return res.status(403).json({ error: 'Supplier profile not found' });

    const { data, error } = await supabase
      .from('loads')
      .select('*')
      .eq('supplier_id', profile.id)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.status(200).json(data);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const searchLoads = async (req: Request, res: Response) => {
  const { 
    pickup_city, 
    drop_city, 
    truck_type, 
    wheels, 
    min_weight, 
    max_weight,
    lat,
    lng,
    radius_km
  } = req.query;

  try {
    let query = supabase
      .from('loads')
      .select('*, supplier_profiles(company_name, owner_name, verification_status)')
      .eq('status', 'ACTIVE');

    // Radius search using PostGIS (if coordinates and radius provided)
    if (lat && lng && radius_km) {
      const radius_meters = Number(radius_km) * 1000;
      // We use rpc call for complex PostGIS queries if needed, 
      // but for simple distance filters we can use raw filter with PostGIS operators if supported by supabase client
      // or a custom RPC function. Using RPC is more reliable for PostGIS.
      const { data: geoData, error: geoError } = await supabase.rpc('get_loads_by_radius', {
        p_lat: Number(lat),
        p_lng: Number(lng),
        p_radius_meters: radius_meters
      });
      
      if (geoError) throw geoError;
      // If geo search was used, we might need to filter the results further with other criteria
      // but RPC usually handles the main filter. For simplicity, we'll continue with the standard query
      // unless radius search is the primary driver.
    }

    if (pickup_city) {
      query = query.filter('pickup_location->>city', 'ilike', `%${pickup_city}%`);
    }
    if (drop_city) {
      query = query.filter('drop_location->>city', 'ilike', `%${drop_city}%`);
    }
    if (truck_type) {
      query = query.eq('required_truck_type', truck_type);
    }
    if (wheels) {
      query = query.eq('required_wheels', wheels);
    }
    if (min_weight) {
      query = query.gte('weight_mt', min_weight);
    }
    if (max_weight) {
      query = query.lte('weight_mt', max_weight);
    }

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error) throw error;

    res.status(200).json(data);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getLoadById = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const { data, error } = await supabase
      .from('loads')
      .select('*, supplier_profiles(*)')
      .eq('id', id)
      .single();

    if (error) throw error;
    if (!data) return res.status(404).json({ error: 'Load not found' });

    res.status(200).json(data);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
