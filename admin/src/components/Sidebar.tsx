"use client";

import Link from 'next/link';
import { useRouter } from 'next/navigation';

const Sidebar = () => {
  const router = useRouter();

  const logout = () => {
    localStorage.removeItem('admin_token');
    router.push('/');
  };

  return (
    <div className="w-64 bg-gray-900 text-white min-h-screen p-4 flex flex-col">
      <h1 className="text-2xl font-bold mb-8 text-blue-400">tranZfort Admin</h1>
      <nav className="flex-1 space-y-2">
        <Link href="/dashboard" className="block p-3 hover:bg-gray-800 rounded transition">
          Dashboard Overview
        </Link>
        <Link href="/dashboard/verifications" className="block p-3 hover:bg-gray-800 rounded transition">
          Verification Queue
        </Link>
        <Link href="/dashboard/loads" className="block p-3 hover:bg-gray-800 rounded transition">
          Load Moderation
        </Link>
        <Link href="/dashboard/users" className="block p-3 hover:bg-gray-800 rounded transition">
          User Management
        </Link>
      </nav>
      <div className="border-t border-gray-800 pt-4 mt-auto">
        <button
          className="w-full text-left p-3 hover:bg-red-900 rounded transition text-red-400"
          onClick={logout}
        >
          Logout
        </button>
      </div>
    </div>
  );
};

export default Sidebar;
