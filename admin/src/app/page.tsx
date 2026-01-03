'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { getSupabaseClient } from '../supabaseClient';

export default function Home() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const onLogin = async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabaseClient();
      // 1) Supabase email/password sign-in
      const { data, error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (signInError) {
        throw new Error(signInError.message);
      }

      if (!data.user) {
        throw new Error('No user returned from Supabase');
      }

      // 2) Check role in users table (expects role column)
      const { data: roleData, error: roleError } = await supabase
        .from('users')
        .select('role')
        .eq('id', data.user.id)
        .single();

      if (roleError) {
        throw new Error(roleError.message || 'Unable to read user role');
      }

      if (roleData?.role !== 'ADMIN') {
        await supabase.auth.signOut();
        throw new Error('Access denied: not an admin');
      }

      // 3) Persist session token for downstream API calls
      const token = data.session?.access_token;
      if (token) {
        localStorage.setItem('admin_token', token);
      }
      localStorage.setItem('admin_user', JSON.stringify(data.user));

      router.push('/dashboard');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="w-full max-w-md bg-white rounded-xl shadow-sm border border-gray-100 p-8">
        <h1 className="text-2xl font-bold text-gray-900">tranZfort Admin</h1>
        <p className="text-sm text-gray-500 mt-1">Sign in with Supabase credentials</p>

        <div className="mt-8 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Email</label>
            <input
              className="mt-1 w-full rounded-md border border-gray-200 p-3"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="email"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Password</label>
            <input
              className="mt-1 w-full rounded-md border border-gray-200 p-3"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
            />
          </div>

          {error ? <div className="text-sm text-red-600">{error}</div> : null}

          <button
            className="w-full rounded-md bg-blue-600 text-white py-3 font-semibold disabled:opacity-60"
            onClick={onLogin}
            disabled={loading}
          >
            {loading ? 'Signing in...' : 'Sign in'}
          </button>

          <p className="text-xs text-gray-500">
            Supabase session token will be stored in <code>localStorage.admin_token</code>
          </p>
        </div>
      </div>
    </div>
  );
}
