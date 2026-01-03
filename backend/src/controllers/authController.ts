import { Request, Response } from 'express';
import { supabase } from '../config/supabase.js';
import { signToken } from '../services/tokenService.js';

export const sendOtp = async (req: Request, res: Response) => {
  const { phone } = req.body;

  if (!phone) {
    return res.status(400).json({ error: 'Phone number is required' });
  }

  try {
    const { error } = await supabase.auth.signInWithOtp({
      phone: `+91${phone}`,
    });

    if (error) throw error;

    res.status(200).json({ message: 'OTP sent successfully' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const verifyOtp = async (req: Request, res: Response) => {
  const { phone, otp } = req.body;

  if (!phone || !otp) {
    return res.status(400).json({ error: 'Phone and OTP are required' });
  }

  try {
    const { data, error } = await supabase.auth.verifyOtp({
      phone: `+91${phone}`,
      token: otp,
      type: 'sms',
    });

    if (error) throw error;
    if (!data.user) throw new Error('User not found after verification');

    // Fetch user role from public.users table
    const { data: dbUser, error: dbError } = await supabase
      .from('users')
      .select('role')
      .eq('id', data.user.id)
      .single();

    let role: 'SUPPLIER' | 'TRUCKER' | 'ADMIN' = 'TRUCKER'; // Default role if not set
    if (dbUser?.role) {
      role = dbUser.role as any;
    } else if (!dbError) {
      // Create user entry if it doesn't exist (first time login)
      // Note: In a real production app, you might want to handle role selection separately
      await supabase.from('users').insert({
        id: data.user.id,
        phone: `+91${phone}`,
        role: 'TRUCKER' // Default
      });
    }

    const token = signToken({
      uid: data.user.id,
      role,
      phone: data.user.phone || `+91${phone}`
    });

    res.status(200).json({ 
      message: 'OTP verified successfully',
      token,
      user: {
        ...data.user,
        role
      }
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
