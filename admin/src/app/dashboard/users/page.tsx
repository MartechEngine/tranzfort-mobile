'use client';

import { useState, useEffect } from 'react';
import { User } from '@/types';
import { getSupabaseClient } from '../../../supabaseClient';

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabaseClient();
      const { data, error: fetchError } = await supabase
        .from('users')
        .select('*')
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;
      setUsers(data as User[]);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'An unknown error occurred');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleUpdateRole = async (userId: string, newRole: string) => {
    try {
      const supabase = getSupabaseClient();
      const { error } = await supabase
        .from('users')
        .update({ role: newRole })
        .eq('id', userId);

      if (error) throw error;
      
      setUsers(users.map(u => u.id === userId ? { ...u, role: newRole as User['role'] } : u));
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : 'An unknown error occurred');
    }
  };

  if (loading) return <div className="p-8 text-center">Loading users...</div>;
  if (error) return <div className="p-8 text-center text-red-500">Error: {error}</div>;

  return (
    <div>
      <h2 className="text-3xl font-bold text-gray-800 mb-6">User Management</h2>
      
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-gray-50 border-bottom border-gray-100">
              <th className="p-4 text-sm font-semibold text-gray-600">User</th>
              <th className="p-4 text-sm font-semibold text-gray-600">Role</th>
              <th className="p-4 text-sm font-semibold text-gray-600">Joined</th>
              <th className="p-4 text-sm font-semibold text-gray-600">Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.length === 0 ? (
              <tr>
                <td colSpan={4} className="p-12 text-center text-gray-400">
                  No users found.
                </td>
              </tr>
            ) : (
              users.map((user) => (
                <tr key={user.id} className="border-t border-gray-50 hover:bg-gray-50 transition">
                  <td className="p-4">
                    <div className="font-medium text-gray-800">{user.phone}</div>
                    <div className="text-xs text-gray-500">ID: {user.id}</div>
                  </td>
                  <td className="p-4 text-sm">
                    <span className={`px-2 py-1 rounded-full text-xs font-bold ${
                      user.role === 'ADMIN' ? 'bg-purple-100 text-purple-700' :
                      user.role === 'SUPPLIER' ? 'bg-blue-100 text-blue-700' :
                      'bg-amber-100 text-amber-700'
                    }`}>
                      {user.role}
                    </span>
                  </td>
                  <td className="p-4 text-sm text-gray-500">
                    {new Date(user.created_at).toLocaleDateString()}
                  </td>
                  <td className="p-4 flex gap-2">
                    <select 
                      className="text-xs border rounded p-1"
                      value={user.role}
                      onChange={(e) => handleUpdateRole(user.id, e.target.value)}
                    >
                      <option value="SUPPLIER">Supplier</option>
                      <option value="TRUCKER">Trucker</option>
                      <option value="ADMIN">Admin</option>
                    </select>
                    <button className="px-3 py-1 bg-red-100 text-red-700 rounded-md text-xs font-bold hover:bg-red-200 transition">
                      Suspend
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
