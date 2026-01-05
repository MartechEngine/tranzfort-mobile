'use client';

import { useState, useEffect } from 'react';
import { getSupabaseClient } from '../../supabaseClient';

interface DashboardStats {
  pendingVerifications: number;
  activeLoads: number;
  totalUsers: number;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats>({
    pendingVerifications: 0,
    activeLoads: 0,
    totalUsers: 0
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const supabase = getSupabaseClient();
        const { data, error } = await supabase.rpc('get_admin_stats');
        
        if (error) throw error;
        if (data) setStats(data);
      } catch (err) {
        console.error('Error fetching dashboard stats:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, []);

  if (loading) return <div className="p-8 text-center">Loading dashboard data...</div>;

  return (
    <div>
      <h2 className="text-3xl font-bold text-gray-800 mb-6">Admin Overview</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <p className="text-gray-500 text-sm font-medium uppercase tracking-wider">Pending Verifications</p>
          <p className="text-4xl font-bold text-blue-600 mt-2">{stats.pendingVerifications}</p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <p className="text-gray-500 text-sm font-medium uppercase tracking-wider">Active Loads</p>
          <p className="text-4xl font-bold text-amber-600 mt-2">{stats.activeLoads}</p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <p className="text-gray-500 text-sm font-medium uppercase tracking-wider">Total Users</p>
          <p className="text-4xl font-bold text-emerald-600 mt-2">{stats.totalUsers}</p>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 text-center py-20">
        <p className="text-gray-400">Welcome to the tranZfort Admin Panel. Use the sidebar to manage the platform.</p>
      </div>
    </div>
  );
}

