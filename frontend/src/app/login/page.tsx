"use client";

import React, { useState } from "react";
import Link from "next/link";
import { 
  Shield, 
  ArrowLeft, 
  ChevronRight, 
  Users, 
  Lock, 
  Wrench,
  Smartphone,
  Eye,
  EyeOff,
  UserCheck
} from "lucide-react";

export default function Login() {
  const [role, setRole] = useState("fleet");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showMobileOverlay, setShowMobileOverlay] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    setTimeout(() => {
      setLoading(false);
      if (role === "admin") {
        window.open("http://localhost:3001", "_blank");
      } else if (role === "fleet") {
        window.open("http://localhost:3002", "_blank");
      } else {
        // Driver, Partner, and Technician mobile app options trigger download details overlay
        setShowMobileOverlay(true);
      }
    }, 1200);
  };

  return (
    <div className="flex flex-col min-h-screen bg-[#020617] text-slate-100 font-sans relative justify-between overflow-hidden">
      
      {/* Background glow orbs */}
      <div className="absolute top-[-200px] left-[-200px] w-96 h-96 bg-blue-500/10 rounded-full blur-[100px] pointer-events-none" />
      <div className="absolute bottom-[-200px] right-[-200px] w-96 h-96 bg-purple-500/10 rounded-full blur-[100px] pointer-events-none" />

      {/* Header */}
      <header className="py-6 px-12 flex justify-between items-center border-b border-white/5 glass-panel z-10">
        <Link href="/" className="flex items-center gap-2 text-sm text-slate-400 hover:text-white transition-colors">
          <ArrowLeft className="w-4 h-4" />
          <span>Back to Homepage</span>
        </Link>
        <div className="flex items-center gap-2">
          <Shield className="w-5 h-5 text-blue-400" />
          <span className="text-sm font-bold tracking-tight text-white">
            ERINA<span className="text-blue-400 font-light">.assistance</span>
          </span>
        </div>
      </header>

      {/* Login Container */}
      <main className="flex-1 flex items-center justify-center py-16 px-6 z-10">
        <div className="w-full max-w-md glass-panel p-8 md:p-10 rounded-3xl relative">
          
          <div className="flex flex-col items-center text-center gap-2 mb-8">
            <div className="w-12 h-12 bg-blue-500/10 rounded-2xl flex items-center justify-center border border-blue-500/20 mb-2">
              <UserCheck className="w-6 h-6 text-blue-400" />
            </div>
            <h2 className="text-2xl font-extrabold text-white">Unified Portal Access</h2>
            <p className="text-slate-400 text-xs">Select your access role to log into your respective account.</p>
          </div>

          <form onSubmit={handleSubmit} className="flex flex-col gap-5">
            
            {/* Role Selector dropdown */}
            <div className="flex flex-col gap-2">
              <label className="text-xs font-semibold text-slate-300">Access Role</label>
              <div className="relative">
                <select
                  value={role}
                  onChange={(e) => setRole(e.target.value)}
                  className="w-full bg-[#0b1329] border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-blue-500 transition-colors appearance-none cursor-pointer"
                >
                  <option value="admin">Operations Administrator</option>
                  <option value="fleet">Fleet Owner / Operator</option>
                  <option value="driver">Commercial Driver (App)</option>
                  <option value="partner">Referral Partner (App)</option>
                  <option value="technician">Roadside Technician (App)</option>
                </select>
                <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400 text-xs">
                  ▼
                </div>
              </div>
            </div>

            {/* Username/Phone Input */}
            <div className="flex flex-col gap-2">
              <label className="text-xs font-semibold text-slate-300">
                {role === "driver" || role === "partner" ? "Mobile Number" : "Username / Email"}
              </label>
              <div className="relative">
                <input
                  type="text"
                  required
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder={role === "driver" || role === "partner" ? "Enter 10-digit number" : "Enter username or email"}
                  className="w-full bg-[#0b1329] border border-white/10 rounded-xl pl-10 pr-4 py-3 text-sm text-white placeholder:text-slate-500 focus:outline-none focus:border-blue-500 transition-colors"
                />
                <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500">
                  <Users className="w-4.5 h-4.5" />
                </div>
              </div>
            </div>

            {/* Password Input */}
            <div className="flex flex-col gap-2">
              <label className="text-xs font-semibold text-slate-300">
                {role === "driver" || role === "partner" ? "OTP code (Dev: 123456)" : "Secure Password"}
              </label>
              <div className="relative">
                <input
                  type={showPassword ? "text" : "password"}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder={role === "driver" || role === "partner" ? "Enter OTP" : "Enter password"}
                  className="w-full bg-[#0b1329] border border-white/10 rounded-xl pl-10 pr-10 py-3 text-sm text-white placeholder:text-slate-500 focus:outline-none focus:border-blue-500 transition-colors"
                />
                <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500">
                  <Lock className="w-4.5 h-4.5" />
                </div>
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white transition-colors"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading}
              className="glow-button mt-4 w-full py-3.5 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl text-sm transition-all duration-300 flex items-center justify-center gap-2"
            >
              {loading ? (
                <span className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <>
                  <span>Sign In to {role.toUpperCase()} Portal</span>
                  <ChevronRight className="w-4 h-4" />
                </>
              )}
            </button>

          </form>

        </div>
      </main>

      {/* Mobile Apps Overlay Modal */}
      {showMobileOverlay && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-6">
          <div className="w-full max-w-md glass-panel p-8 rounded-3xl relative flex flex-col gap-6">
            
            <div className="flex flex-col items-center text-center gap-2">
              <div className="w-12 h-12 bg-indigo-500/10 rounded-2xl flex items-center justify-center border border-indigo-500/20 mb-2">
                <Smartphone className="w-6 h-6 text-indigo-400" />
              </div>
              <h3 className="text-xl font-bold text-white uppercase">{role} Application</h3>
              <p className="text-slate-400 text-xs leading-relaxed mt-1">
                The **{role} mobile portal** is designed specifically for touch screens and mobile configurations.
              </p>
            </div>

            <div className="bg-slate-950/60 border border-white/5 rounded-2xl p-4 flex flex-col gap-3">
              <span className="text-slate-400 text-[10px] font-bold uppercase tracking-wider">Developer Active Session</span>
              
              <div className="flex flex-col gap-1">
                <span className="text-xs text-slate-300 font-semibold">Active Android Emulator:</span>
                <span className="text-xs text-slate-400 font-mono">sdk gphone64 arm64 (emulator-5554)</span>
              </div>

              <div className="flex flex-col gap-1 border-t border-white/5 pt-2.5">
                <span className="text-xs text-slate-300 font-semibold">Mock Login Credentials:</span>
                <span className="text-xs text-slate-400 font-mono">Phone: +91 9988776655</span>
                <span className="text-xs text-slate-400 font-mono">OTP Code: 123456</span>
              </div>
            </div>

            <div className="flex flex-col gap-2">
              <button 
                onClick={() => setShowMobileOverlay(false)}
                className="w-full py-3 bg-slate-900 border border-white/10 hover:bg-slate-950 font-semibold rounded-xl text-sm text-white transition-colors"
              >
                Dismiss Gateway
              </button>
            </div>

          </div>
        </div>
      )}

      {/* Footer */}
      <footer className="py-6 border-t border-white/5 text-center text-xs text-slate-500 z-10">
        <p>&copy; {new Date().getFullYear()} Erina Assistance Platform. All rights reserved.</p>
      </footer>

    </div>
  );
}
