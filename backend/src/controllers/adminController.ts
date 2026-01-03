import { Request, Response } from 'express';
import { supabase } from '../config/supabase.js';

export const getAdminStats = async (req: Request, res: Response) => {
  try {
    // 1. Get pending verifications count
    const { count: pendingVerifications, error: vError } = await supabase
      .from('verifications')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'PENDING');

    if (vError) throw vError;

    // 2. Get active loads count
    const { count: activeLoads, error: lError } = await supabase
      .from('loads')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'ACTIVE');

    if (lError) throw lError;

    // 3. Get total users count
    const { count: totalUsers, error: uError } = await supabase
      .from('users')
      .select('*', { count: 'exact', head: true });

    if (uError) throw uError;

    res.status(200).json({
      pendingVerifications: pendingVerifications || 0,
      activeLoads: activeLoads || 0,
      totalUsers: totalUsers || 0,
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getPendingVerifications = async (req: Request, res: Response) => {
  try {
    const { data, error } = await supabase
      .from('verifications')
      .select('*, users(phone, role)')
      .eq('status', 'PENDING')
      .order('created_at', { ascending: true });

    if (error) throw error;

    res.status(200).json(data);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const approveVerification = async (req: Request, res: Response) => {
  const { id } = req.params;
  try {
    const { data: verification, error: fetchError } = await supabase
      .from('verifications')
      .select('user_id')
      .eq('id', id)
      .single();

    if (fetchError || !verification) throw new Error('Verification not found');

    // 1. Update verification status
    const { error: vError } = await supabase
      .from('verifications')
      .update({ status: 'APPROVED' })
      .eq('id', id);

    if (vError) throw vError;

    // 2. Update profile status
    const { data: user } = await supabase.from('users').select('role').eq('id', verification.user_id).single();
    if (user) {
      const table = user.role === 'SUPPLIER' ? 'supplier_profiles' : 'trucker_profiles';
      await supabase.from(table).update({ verification_status: 'VERIFIED' }).eq('user_id', verification.user_id);
    }

    res.status(200).json({ message: 'Verification approved' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const rejectVerification = async (req: Request, res: Response) => {
  const { id } = req.params;
  const { notes } = req.body;
  try {
    const { data: verification, error: fetchError } = await supabase
      .from('verifications')
      .select('user_id')
      .eq('id', id)
      .single();

    if (fetchError || !verification) throw new Error('Verification not found');

    const { error: vError } = await supabase
      .from('verifications')
      .update({ status: 'REJECTED', admin_notes: notes })
      .eq('id', id);

    if (vError) throw vError;

    // Update profile status
    const { data: user } = await supabase.from('users').select('role').eq('id', verification.user_id).single();
    if (user) {
      const table = user.role === 'SUPPLIER' ? 'supplier_profiles' : 'trucker_profiles';
      await supabase.from(table).update({ verification_status: 'REJECTED' }).eq('user_id', verification.user_id);
    }

    res.status(200).json({ message: 'Verification rejected' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getAllLoads = async (req: Request, res: Response) => {
  try {
    const { data, error } = await supabase
      .from('loads')
      .select('*, supplier_profiles(company_name, owner_name)')
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.status(200).json(data);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const deleteLoad = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const { error } = await supabase.from('loads').delete().eq('id', id);
    if (error) throw error;

    res.status(200).json({ message: 'Load deleted' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
