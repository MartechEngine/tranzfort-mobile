'use client';

import { useEffect, useState } from 'react';
import { Load } from '@/types';
import { getSupabaseClient } from '../../../supabaseClient';

export default function LoadsPage() {
  const [loads, setLoads] = useState<Load[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchLoads = async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabaseClient();
      const { data, error: fetchError } = await supabase
        .from('loads')
        .select('*, supplier_profiles(company_name, owner_name)')
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;
      setLoads(data as any);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLoads();
  }, []);

  const deleteLoad = async (id: string) => {
    const ok = window.confirm('Delete this load?');
    if (!ok) return;
    
    try {
      const supabase = getSupabaseClient();
      const { error } = await supabase
        .from('loads')
        .delete()
        .eq('id', id);

      if (error) throw error;
      await fetchLoads();
    } catch (err: any) {
      alert(err.message);
    }
  };

  if (loading) return <div className="p-8 text-center">Loading loads...</div>;
  if (error) return <div className="p-8 text-center text-red-500">Error: {error}</div>;

  return (
    <div>
      <h2 className="text-3xl font-bold text-gray-800 mb-6">Load Moderation</h2>
      
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-gray-50 border-bottom border-gray-100">
              <th className="p-4 text-sm font-semibold text-gray-600">Route</th>
              <th className="p-4 text-sm font-semibold text-gray-600">Details</th>
              <th className="p-4 text-sm font-semibold text-gray-600">Status</th>
              <th className="p-4 text-sm font-semibold text-gray-600">Date</th>
              <th className="p-4 text-sm font-semibold text-gray-600">Actions</th>
            </tr>
          </thead>
          <tbody>
            {loads.length === 0 ? (
              <tr>
                <td colSpan={5} className="p-12 text-center text-gray-400">
                  No active loads to moderate.
                </td>
              </tr>
            ) : (
              loads.map((load) => (
                <tr key={load.id} className="border-t border-gray-50 hover:bg-gray-50 transition">
                  <td className="p-4">
                    <div className="font-medium text-gray-800">
                      {load.pickup_location.city} → {load.drop_location.city}
                    </div>
                  </td>
                  <td className="p-4 text-sm text-gray-600">
                    {load.material_type} • {load.weight_mt} MT
                  </td>
                  <td className="p-4">
                    <span className={`px-2 py-1 rounded-full text-xs font-bold ${
                      load.status === 'ACTIVE' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'
                    }`}>
                      {load.status}
                    </span>
                  </td>
                  <td className="p-4 text-sm text-gray-500">
                    {new Date(load.created_at).toLocaleDateString()}
                  </td>
                  <td className="p-4 flex gap-2">
                    <button
                      className="px-3 py-1 bg-red-100 text-red-700 rounded-md text-xs font-bold hover:bg-red-200 transition"
                      onClick={() => deleteLoad(load.id)}
                    >
                      Delete
                    </button>
                    <button className="px-3 py-1 bg-gray-100 text-gray-700 rounded-md text-xs font-bold hover:bg-gray-200 transition">
                      Flag
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
