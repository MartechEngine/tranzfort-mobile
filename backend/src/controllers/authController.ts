import { Request, Response } from 'express';
import { supabase } from '../config/supabase.js';

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

    res.status(200).json({ 
      message: 'OTP verified successfully',
      session: data.session,
      user: data.user
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
