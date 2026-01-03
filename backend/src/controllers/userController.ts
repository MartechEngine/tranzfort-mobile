import { Request, Response } from 'express';
import { supabase } from '../config/supabase.js';

export const getProfile = async (req: Request, res: Response) => {
  const userId = req.user?.id;

  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const { data, error } = await supabase
      .from('users')
      .select('*, supplier_profiles(*), trucker_profiles(*)')
      .eq('id', userId)
      .single();

    if (error) throw error;

    res.status(200).json(data);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const updateProfile = async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { role, profileData } = req.body;

  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    // 1. Update user role if changed
    if (role) {
      const { error: userError } = await supabase
        .from('users')
        .update({ role })
        .eq('id', userId);
      if (userError) throw userError;
    }

    // 2. Update specific profile table based on role
    const table = role === 'SUPPLIER' ? 'supplier_profiles' : 'trucker_profiles';
    const { data, error } = await supabase
      .from(table)
      .upsert({ user_id: userId, ...profileData })
      .select()
      .single();

    if (error) throw error;

    res.status(200).json({ message: 'Profile updated successfully', profile: data });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getAllUsers = async (req: Request, res: Response) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.status(200).json(data);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const updateUser = async (req: Request, res: Response) => {
  const { id } = req.params;
  const { role } = req.body;

  try {
    const { data, error } = await supabase
      .from('users')
      .update({ role })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    res.status(200).json({ message: 'User updated successfully', user: data });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
