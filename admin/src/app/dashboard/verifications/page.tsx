'use client';

import { useEffect, useState } from 'react';
import { VerificationRequest } from '@/types';
import { getSupabaseClient } from '../../../supabaseClient';

export default function VerificationsPage() {
  const [verifications, setVerifications] = useState<VerificationRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchVerifications = async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabaseClient();
      const { data, error: fetchError } = await supabase
        .from('verifications')
        .select('*, users(phone, role)')
        .eq('status', 'PENDING')
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;
      setVerifications(data as any);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVerifications();
  }, []);

  const approve = async (id: string) => {
    try {
      const supabase = getSupabaseClient();
      const verification = verifications.find(v => v.id === id);
      if (!verification) return;

      const { error } = await supabase.rpc('approve_verification', {
        p_user_id: verification.user_id
      });

      if (error) throw error;
      await fetchVerifications();
    } catch (err: any) {
      alert(err.message);
    }
  };

  const reject = async (id: string) => {
    try {
      const notes = window.prompt('Reject notes (optional):') ?? '';
      const supabase = getSupabaseClient();
      const verification = verifications.find(v => v.id === id);
      if (!verification) return;

      const { error } = await supabase.rpc('reject_verification', {
        p_user_id: verification.user_id,
        p_admin_notes: notes
      });

      if (error) throw error;
      await fetchVerifications();
    } catch (err: any) {
      alert(err.message);
    }
  };

  if (loading) return <div className="p-8 text-center">Loading verifications...</div>;
  if (error) return <div className="p-8 text-center text-red-500">Error: {error}</div>;

  return (
    <div>
      <h2 className="text-3xl font-bold text-gray-800 mb-6">Verification Queue</h2>
      
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-gray-50 border-bottom border-gray-100">
              <th className="p-4 text-sm font-semibold text-gray-600">User</th>
              <th className="p-4 text-sm font-semibold text-gray-600">Type</th>
              <th className="p-4 text-sm font-semibold text-gray-600">Document</th>
              <th className="p-4 text-sm font-semibold text-gray-600">Date</th>
              <th className="p-4 text-sm font-semibold text-gray-600">Actions</th>
            </tr>
          </thead>
          <tbody>
            {verifications.length === 0 ? (
              <tr>
                <td colSpan={5} className="p-12 text-center text-gray-400">
                  No pending verification requests.
                </td>
              </tr>
            ) : (
              verifications.map((req) => (
                <tr key={req.id} className="border-t border-gray-50 hover:bg-gray-50 transition">
                  <td className="p-4">
                    <div className="font-medium text-gray-800">{req.users.phone}</div>
                    <div className="text-xs text-gray-500">{req.users.role}</div>
                  </td>
                  <td className="p-4 text-sm text-gray-600">{req.document_type}</td>
                  <td className="p-4">
                    <a href={req.document_url} target="_blank" rel="noopener noreferrer" className="text-blue-500 hover:underline text-sm font-medium">
                      View File
                    </a>
                  </td>
                  <td className="p-4 text-sm text-gray-500">
                    {new Date(req.created_at).toLocaleDateString()}
                  </td>
                  <td className="p-4 flex gap-2">
                    <button
                      className="px-3 py-1 bg-emerald-100 text-emerald-700 rounded-md text-xs font-bold hover:bg-emerald-200 transition"
                      onClick={() => approve(req.id)}
                    >
                      Approve
                    </button>
                    <button
                      className="px-3 py-1 bg-red-100 text-red-700 rounded-md text-xs font-bold hover:bg-red-200 transition"
                      onClick={() => reject(req.id)}
                    >
                      Reject
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
