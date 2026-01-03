import { VerificationRequest, Load } from '@/types';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

export const adminService = {
  async getVerifications(): Promise<VerificationRequest[]> {
    const response = await fetch(`${API_BASE_URL}/admin/verifications`);
    if (!response.ok) throw new Error('Failed to fetch verifications');
    return response.json();
  },

  async approveVerification(id: string): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/admin/verifications/${id}/approve`, {
      method: 'POST',
    });
    if (!response.ok) throw new Error('Failed to approve verification');
  },

  async rejectVerification(id: string, notes: string): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/admin/verifications/${id}/reject`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ notes }),
    });
    if (!response.ok) throw new Error('Failed to reject verification');
  },

  async getLoads(): Promise<Load[]> {
    const response = await fetch(`${API_BASE_URL}/loads`); // Or admin specific load route
    if (!response.ok) throw new Error('Failed to fetch loads');
    return response.json();
  },

  async deleteLoad(id: string): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/loads/${id}`, {
      method: 'DELETE',
    });
    if (!response.ok) throw new Error('Failed to delete load');
  },
};
