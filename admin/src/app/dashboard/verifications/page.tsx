'use client';

import { useEffect, useState } from 'react';
import { VerificationRequest } from '@/types';

export default function VerificationsPage() {
  const [verifications, setVerifications] = useState<VerificationRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const adminToken = typeof window !== 'undefined' ? localStorage.getItem('admin_token') : null;

  const fetchVerifications = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await fetch('http://localhost:3000/admin/verifications', {
        headers: {
          Authorization: `Bearer ${adminToken ?? ''}`,
        },
      });
      if (!response.ok) throw new Error('Failed to fetch verifications');
      const data = (await response.json()) as VerificationRequest[];
      setVerifications(data);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVerifications();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const approve = async (id: string) => {
    await fetch(`http://localhost:3000/admin/verifications/${id}/approve`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${adminToken ?? ''}`,
      },
    });
    await fetchVerifications();
  };

  const reject = async (id: string) => {
    const notes = window.prompt('Reject notes (optional):') ?? '';
    await fetch(`http://localhost:3000/admin/verifications/${id}/reject`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken ?? ''}`,
      },
      body: JSON.stringify({ notes }),
    });
    await fetchVerifications();
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
