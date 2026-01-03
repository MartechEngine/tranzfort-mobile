import { Request, Response } from 'express';
import { supabase } from '../config/supabase.js';

export const submitVerification = async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { document_type, document_url } = req.body;

  if (!userId || !document_type || !document_url) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    const { data, error } = await supabase
      .from('verifications')
      .upsert({
        user_id: userId,
        document_type,
        document_url,
        status: 'PENDING'
      })
      .select()
      .single();

    if (error) throw error;

    // Update user profile status
    const { data: user } = await supabase.from('users').select('role').eq('id', userId).single();
    if (user) {
      const table = user.role === 'SUPPLIER' ? 'supplier_profiles' : 'trucker_profiles';
      await supabase.from(table).update({ verification_status: 'PENDING' }).eq('user_id', userId);
    }

    res.status(201).json({ message: 'Verification submitted successfully', verification: data });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getMyVerificationStatus = async (req: Request, res: Response) => {
  const userId = req.user?.id;

  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const { data, error } = await supabase
      .from('verifications')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error && error.code !== 'PGRST116') throw error;

    res.status(200).json(data || { status: 'UNVERIFIED' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
