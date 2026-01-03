import Image from "next/image";
import Link from "next/link";

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen bg-white text-slate-900 font-sans">
      {/* Navbar */}
      <nav className="flex items-center justify-between px-6 py-4 max-w-7xl mx-auto w-full">
        <div className="flex items-center gap-2">
          <Image src="/logo-tranzfort.png" alt="tranZfort Logo" width={40} height={40} className="rounded-lg" />
          <span className="text-2xl font-bold tracking-tight text-blue-600">tranZfort</span>
        </div>
        <div className="hidden md:flex gap-8 text-sm font-medium">
          <a href="#how-it-works" className="hover:text-blue-600 transition">How it Works</a>
          <a href="#features" className="hover:text-blue-600 transition">Features</a>
          <a href="#safety" className="hover:text-blue-600 transition">Safety</a>
        </div>
      </nav>

      {/* Hero Section */}
      <header className="px-6 py-20 md:py-32 max-w-7xl mx-auto w-full text-center">
        <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight mb-6 bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
          The Future of Truck Load Discovery
        </h1>
        <p className="text-xl md:text-2xl text-slate-600 mb-10 max-w-3xl mx-auto leading-relaxed">
          Connect directly with suppliers and truckers across India. No commissions, no intermediaries, just pure logistics.
        </p>
        
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-16">
          <Link href="#" className="w-full sm:w-auto px-8 py-4 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 transition shadow-lg shadow-blue-200 text-center">
            Download Android App
          </Link>
          <Link href="#" className="w-full sm:w-auto px-8 py-4 bg-slate-900 text-white font-bold rounded-xl hover:bg-slate-800 transition shadow-lg shadow-slate-200 text-center">
            Download iOS App
          </Link>
        </div>

        <div className="inline-flex items-center gap-2 px-4 py-2 bg-slate-100 rounded-full text-sm font-semibold text-slate-600">
          <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
          Trusted by 5,000+ verified users
        </div>
      </header>

      {/* Value Props */}
      <section id="features" className="bg-slate-50 py-24 px-6">
        <div className="max-w-7xl mx-auto w-full">
          <h2 className="text-3xl md:text-5xl font-bold text-center mb-16">Built for Speed & Trust</h2>
          <div className="grid md:grid-cols-3 gap-12 text-center">
            <div className="p-8 bg-white rounded-2xl shadow-sm border border-slate-100">
              <div className="w-16 h-16 bg-blue-100 text-blue-600 rounded-2xl flex items-center justify-center mx-auto mb-6 text-2xl font-bold">⚡</div>
              <h3 className="text-xl font-bold mb-4">Post in 60s</h3>
              <p className="text-slate-600">Suppliers can list their requirements in seconds. No complex forms.</p>
            </div>
            <div className="p-8 bg-white rounded-2xl shadow-sm border border-slate-100">
              <div className="w-16 h-16 bg-blue-100 text-blue-600 rounded-2xl flex items-center justify-center mx-auto mb-6 text-2xl font-bold">🔍</div>
              <h3 className="text-xl font-bold mb-4">Find in 30s</h3>
              <p className="text-slate-600">Advanced filtering and nearby search to find the perfect load instantly.</p>
            </div>
            <div className="p-8 bg-white rounded-2xl shadow-sm border border-slate-100">
              <div className="w-16 h-16 bg-blue-100 text-blue-600 rounded-2xl flex items-center justify-center mx-auto mb-6 text-2xl font-bold">💬</div>
              <h3 className="text-xl font-bold mb-4">Direct Connect</h3>
              <p className="text-slate-600">In-app chat and one-tap calling. No middleman involved.</p>
            </div>
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section id="how-it-works" className="py-24 px-6 max-w-7xl mx-auto w-full">
        <div className="grid md:grid-cols-2 gap-16 items-center">
          <div>
            <h2 className="text-3xl md:text-5xl font-bold mb-8">How it Works</h2>
            <div className="space-y-8">
              <div className="flex gap-6">
                <div className="flex-shrink-0 w-10 h-10 bg-blue-600 text-white rounded-full flex items-center justify-center font-bold">1</div>
                <div>
                  <h4 className="text-lg font-bold mb-2">Register & Verify</h4>
                  <p className="text-slate-600">Sign up with your mobile number. Suppliers and truckers get verified for trust.</p>
                </div>
              </div>
              <div className="flex gap-6">
                <div className="flex-shrink-0 w-10 h-10 bg-blue-600 text-white rounded-full flex items-center justify-center font-bold">2</div>
                <div>
                  <h4 className="text-lg font-bold mb-2">Post or Discover</h4>
                  <p className="text-slate-600">Suppliers post loads. Truckers search for loads on their preferred routes.</p>
                </div>
              </div>
              <div className="flex gap-6">
                <div className="flex-shrink-0 w-10 h-10 bg-blue-600 text-white rounded-full flex items-center justify-center font-bold">3</div>
                <div>
                  <h4 className="text-lg font-bold mb-2">Deal Directly</h4>
                  <p className="text-slate-600">Chat or call directly. Negotiate and finalize terms without any third party.</p>
                </div>
              </div>
            </div>
          </div>
          <div className="bg-slate-200 rounded-3xl aspect-[4/5] flex items-center justify-center text-slate-400 font-bold italic">
            App Mockup Placeholder
          </div>
        </div>
      </section>

      {/* Safety & Fairness */}
      <section id="safety" className="bg-blue-600 py-24 px-6 text-white rounded-[3rem] mx-6 mb-12">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-3xl md:text-5xl font-bold mb-8">Zero Commissions. Total Transparency.</h2>
          <p className="text-xl mb-12 opacity-90 leading-relaxed">
            tranZfort is an open platform. We don&apos;t handle payments, escrow money, or take a cut from your freight. Our goal is to reduce friction, not create it.
          </p>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            <div className="bg-white/10 p-6 rounded-2xl backdrop-blur-sm">
              <div className="text-2xl mb-2">🛡️</div>
              <div className="text-sm font-bold uppercase tracking-widest text-center">Verified Users</div>
            </div>
            <div className="bg-white/10 p-6 rounded-2xl backdrop-blur-sm">
              <div className="text-2xl mb-2">💸</div>
              <div className="text-sm font-bold uppercase tracking-widest text-center">No Hidden Fees</div>
            </div>
            <div className="bg-white/10 p-6 rounded-2xl backdrop-blur-sm">
              <div className="text-2xl mb-2">🤝</div>
              <div className="text-sm font-bold uppercase tracking-widest text-center">Direct Deal</div>
            </div>
            <div className="bg-white/10 p-6 rounded-2xl backdrop-blur-sm">
              <div className="text-2xl mb-2">📵</div>
              <div className="text-sm font-bold uppercase tracking-widest text-center">No Brokerage</div>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Footer */}
      <footer className="px-6 py-12 border-t border-slate-100 max-w-7xl mx-auto w-full">
        <div className="flex flex-col md:flex-row justify-between items-center gap-8">
          <div className="flex items-center gap-2 grayscale opacity-50">
            <Image src="/logo-tranzfort.png" alt="tranZfort Logo" width={30} height={30} className="rounded-md" />
            <span className="text-xl font-bold tracking-tight">tranZfort</span>
          </div>
          <div className="flex gap-8 text-sm text-slate-500 font-medium text-center">
            <a href="#" className="hover:text-blue-600 transition">Privacy Policy</a>
            <a href="#" className="hover:text-blue-600 transition">Terms of Service</a>
            <a href="mailto:support@tranzfort.com" className="hover:text-blue-600 transition">Contact Us</a>
          </div>
          <p className="text-xs text-slate-400">© 2026 tranZfort Logistics. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
}
