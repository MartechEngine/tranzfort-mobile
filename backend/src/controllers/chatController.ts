import { Request, Response } from 'express';
import { supabase } from '../config/supabase.js';

export const initiateChat = async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { load_id } = req.body;

  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    // 1. Get trucker profile id
    const { data: truckerProfile, error: truckerError } = await supabase
      .from('trucker_profiles')
      .select('id, verification_status')
      .eq('user_id', userId)
      .single();

    if (truckerError || !truckerProfile) {
      return res.status(403).json({ error: 'Trucker profile not found' });
    }

    if (truckerProfile.verification_status !== 'VERIFIED') {
      return res.status(403).json({ error: 'Only verified truckers can initiate chat' });
    }

    // 2. Check if load is active
    const { data: load, error: loadError } = await supabase
      .from('loads')
      .select('status')
      .eq('id', load_id)
      .single();

    if (loadError || !load || load.status !== 'ACTIVE') {
      return res.status(400).json({ error: 'Load is not active' });
    }

    // 3. Create or get existing chat thread
    const { data: existingChat } = await supabase
      .from('chats')
      .select('id')
      .eq('load_id', load_id)
      .eq('trucker_id', truckerProfile.id)
      .single();

    if (existingChat) {
      return res.status(200).json(existingChat);
    }

    const { data: newChat, error: chatError } = await supabase
      .from('chats')
      .insert({
        load_id,
        trucker_id: truckerProfile.id,
        status: 'ACTIVE'
      })
      .select()
      .single();

    if (chatError) throw chatError;

    res.status(201).json(newChat);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const sendMessage = async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id: chat_id } = req.params;
  const { message } = req.body;

  if (!userId || !chat_id || !message) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    const { data, error } = await supabase
      .from('chat_messages')
      .insert({
        chat_id,
        sender_id: userId,
        message
      })
      .select()
      .single();

    if (error) throw error;

    res.status(201).json(data);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getChatMessages = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const { data, error } = await supabase
      .from('chat_messages')
      .select('*')
      .eq('chat_id', id)
      .order('created_at', { ascending: true });

    if (error) throw error;

    res.status(200).json(data);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};

export const getMyChats = async (req: Request, res: Response) => {
  const userId = req.user?.id;

  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    // This query is a bit complex as it needs to handle both supplier and trucker roles
    // For simplicity, we fetch all chats where the user is either the load owner (supplier) 
    // or the chat initiator (trucker)
    
    const { data: profile } = await supabase
      .from('users')
      .select('role, supplier_profiles(id), trucker_profiles(id)')
      .eq('id', userId)
      .single();

    if (!profile) return res.status(404).json({ error: 'User not found' });

    let query = supabase.from('chats').select('*, loads(*, supplier_profiles(*)), trucker_profiles(*)');

    if (profile.role === 'SUPPLIER') {
      const supplierId = profile.supplier_profiles[0]?.id;
      query = query.filter('loads.supplier_id', 'eq', supplierId);
    } else {
      const truckerId = profile.trucker_profiles[0]?.id;
      query = query.eq('trucker_id', truckerId);
    }

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error) throw error;

    res.status(200).json(data);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
};
