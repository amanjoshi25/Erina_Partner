"use client";

import React, { useState, useEffect } from "react";
import { 
  Shield, 
  Users, 
  CheckCircle, 
  AlertTriangle, 
  TrendingUp, 
  MapPin, 
  CreditCard, 
  ArrowRight, 
  Clock, 
  Activity,
  Layers,
  Wrench,
  Sparkles,
  Unlock
} from "lucide-react";

export default function Home() {
  const [token, setToken] = useState<string | null>(null);

  useEffect(() => {
    if (typeof window !== "undefined") {
      const params = new URLSearchParams(window.location.search);
      const urlToken = params.get("token");
      if (urlToken) {
        setToken(urlToken);
        localStorage.setItem("admin_token", urlToken);
      } else {
        const localToken = localStorage.getItem("admin_token");
        if (localToken) setToken(localToken);
      }
    }
  }, []);

  return (
    <div className="flex flex-col min-h-screen bg-[#020617] text-slate-100 font-sans selection:bg-indigo-500/30 selection:text-indigo-200">
      
      {/* Background Orbs */}
      <div className="absolute top-0 left-1/4 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute top-1/3 right-1/4 w-96 h-96 bg-purple-500/10 rounded-full blur-3xl pointer-events-none" />
      
      {/* Header */}
      <header className="sticky top-0 z-50 glass-panel border-b border-white/5 py-4 px-6 md:px-12 flex justify-between items-center">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-indigo-600/20 border border-indigo-500/30 rounded-xl">
            <Shield className="w-6 h-6 text-indigo-400" />
          </div>
          <div>
            <span className="text-xl font-bold tracking-tight text-white font-sans">
              ERINA<span className="text-indigo-400 font-light">.assistance</span>
            </span>
            <span className="hidden sm:inline-block ml-3 px-2 py-0.5 text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 rounded-full">
              Control Center
            </span>
          </div>
        </div>

        <nav className="flex items-center gap-6">
          <div className="flex items-center gap-2 text-sm text-slate-400">
            <span className="w-2.5 h-2.5 bg-emerald-500 rounded-full animate-pulse" />
            <span className="hidden md:inline">System Status:</span>
            <span className="font-semibold text-emerald-400">Online</span>
          </div>
          <div className="h-4 w-px bg-slate-800" />
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center font-bold text-indigo-400 text-sm">
              OP
            </div>
          </div>
        </nav>
      </header>

      {/* Main Container */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-6 py-10 md:px-12 flex flex-col gap-10">
        
        {token && (
          <div className="flex items-center justify-between p-4 bg-emerald-500/10 border border-emerald-500/25 text-emerald-400 rounded-2xl text-xs gap-3 animate-fade-in">
            <div className="flex items-center gap-2.5">
              <div className="p-1.5 bg-emerald-500/10 rounded-lg">
                <Unlock className="w-4 h-4 text-emerald-400 shrink-0" />
              </div>
              <div>
                <span className="font-bold uppercase tracking-wider block text-[10px]">Single-Sign-On Verified</span>
                <span className="text-slate-400 font-mono text-[10px] truncate max-w-md block mt-0.5">Session Token: {token}</span>
              </div>
            </div>
            <button 
              onClick={() => {
                localStorage.removeItem("admin_token");
                window.location.href = "http://localhost:3000/login";
              }}
              className="px-3 py-1.5 bg-slate-900 hover:bg-slate-950 border border-white/5 text-slate-300 font-semibold rounded-lg hover:text-red-400 transition-colors cursor-pointer"
            >
              Sign out
            </button>
          </div>
        )}

        {/* Title and Intro */}
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-3xl md:text-4xl font-extrabold tracking-tight text-white mb-2">
              Operations Control Center
            </h1>
            <p className="text-slate-400 text-base max-w-2xl">
              Real-time subscription management, document compliance verification, and technician dispatch log.
            </p>
          </div>
          <button className="glow-button flex items-center justify-center gap-2 px-5 py-3 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-xl text-sm transition-all duration-300">
            <Sparkles className="w-4 h-4" />
            Launch Live Dispatch
          </button>
        </div>

        {/* Dashboard Grid - Stats */}
        <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          
          <div className="glass-panel premium-card p-6 rounded-2xl">
            <div className="flex items-center justify-between mb-4">
              <span className="text-sm font-medium text-slate-400">Active Subscriptions</span>
              <div className="p-2 bg-blue-500/10 rounded-lg">
                <CreditCard className="w-5 h-5 text-blue-400" />
              </div>
            </div>
            <h3 className="text-2xl font-bold text-white mb-1">12,480</h3>
            <div className="flex items-center gap-1.5 text-xs text-emerald-400">
              <TrendingUp className="w-3.5 h-3.5" />
              <span>+12.4% this month</span>
            </div>
          </div>

          <div className="glass-panel premium-card p-6 rounded-2xl">
            <div className="flex items-center justify-between mb-4">
              <span className="text-sm font-medium text-slate-400">Pending KYC Review</span>
              <div className="p-2 bg-amber-500/10 rounded-lg">
                <Users className="w-5 h-5 text-amber-400" />
              </div>
            </div>
            <h3 className="text-2xl font-bold text-white mb-1">43</h3>
            <div className="flex items-center gap-1.5 text-xs text-amber-400">
              <Clock className="w-3.5 h-3.5" />
              <span>Avg queue time: 8 mins</span>
            </div>
          </div>

          <div className="glass-panel premium-card p-6 rounded-2xl">
            <div className="flex items-center justify-between mb-4">
              <span className="text-sm font-medium text-slate-400">Technicians Online</span>
              <div className="p-2 bg-emerald-500/10 rounded-lg">
                <Wrench className="w-5 h-5 text-emerald-400" />
              </div>
            </div>
            <h3 className="text-2xl font-bold text-white mb-1">189</h3>
            <div className="flex items-center gap-1.5 text-xs text-emerald-400">
              <Activity className="w-3.5 h-3.5" />
              <span>Active in Bangalore</span>
            </div>
          </div>

          <div className="glass-panel premium-card p-6 rounded-2xl">
            <div className="flex items-center justify-between mb-4">
              <span className="text-sm font-medium text-slate-400">Open RSA Jobs</span>
              <div className="p-2 bg-rose-500/10 rounded-lg">
                <AlertTriangle className="w-5 h-5 text-rose-400" />
              </div>
            </div>
            <h3 className="text-2xl font-bold text-white mb-1">14</h3>
            <div className="flex items-center gap-1.5 text-xs text-rose-400">
              <MapPin className="w-3.5 h-3.5" />
              <span>3 urgent requests</span>
            </div>
          </div>

        </section>

        {/* Dynamic Panels */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          
          {/* Quick Action Navigation Grid */}
          <div className="lg:col-span-2 flex flex-col gap-6">
            <h2 className="text-xl font-bold text-white flex items-center gap-2">
              <Layers className="w-5 h-5 text-indigo-400" /> Quick Operations
            </h2>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              
              <div className="glass-panel premium-card p-6 rounded-2xl flex flex-col justify-between h-52 group cursor-pointer">
                <div>
                  <div className="w-10 h-10 bg-indigo-500/10 rounded-xl flex items-center justify-center mb-4">
                    <Shield className="w-5 h-5 text-indigo-400" />
                  </div>
                  <h3 className="text-lg font-bold text-white mb-1 group-hover:text-indigo-300 transition-colors">
                    Verify Driver KYC
                  </h3>
                  <p className="text-slate-400 text-xs leading-relaxed">
                    Verify pending RC smartcards, Aadhaar, and driving licenses for active onboarding.
                  </p>
                </div>
                <div className="flex items-center gap-2 text-xs font-semibold text-indigo-400 mt-4">
                  <span>Go to Verification</span>
                  <ArrowRight className="w-3.5 h-3.5 transform group-hover:translate-x-1 transition-transform" />
                </div>
              </div>

              <div className="glass-panel premium-card p-6 rounded-2xl flex flex-col justify-between h-52 group cursor-pointer">
                <div>
                  <div className="w-10 h-10 bg-emerald-500/10 rounded-xl flex items-center justify-center mb-4">
                    <CreditCard className="w-5 h-5 text-emerald-400" />
                  </div>
                  <h3 className="text-lg font-bold text-white mb-1 group-hover:text-emerald-300 transition-colors">
                    Manage Subscriptions
                  </h3>
                  <p className="text-slate-400 text-xs leading-relaxed">
                    Control active packages, customize fleet pricing, and check renewal cycles.
                  </p>
                </div>
                <div className="flex items-center gap-2 text-xs font-semibold text-emerald-400 mt-4">
                  <span>View Subscriptions</span>
                  <ArrowRight className="w-3.5 h-3.5 transform group-hover:translate-x-1 transition-transform" />
                </div>
              </div>

              <div className="glass-panel premium-card p-6 rounded-2xl flex flex-col justify-between h-52 group cursor-pointer">
                <div>
                  <div className="w-10 h-10 bg-rose-500/10 rounded-xl flex items-center justify-center mb-4">
                    <MapPin className="w-5 h-5 text-rose-400" />
                  </div>
                  <h3 className="text-lg font-bold text-white mb-1 group-hover:text-rose-300 transition-colors">
                    RSA Dispatch Logs
                  </h3>
                  <p className="text-slate-400 text-xs leading-relaxed">
                    Track technicians live, assign closest technicians, and manage emergency SOS dispatches.
                  </p>
                </div>
                <div className="flex items-center gap-2 text-xs font-semibold text-rose-400 mt-4">
                  <span>Check Dispatch Board</span>
                  <ArrowRight className="w-3.5 h-3.5 transform group-hover:translate-x-1 transition-transform" />
                </div>
              </div>

              <div className="glass-panel premium-card p-6 rounded-2xl flex flex-col justify-between h-52 group cursor-pointer">
                <div>
                  <div className="w-10 h-10 bg-blue-500/10 rounded-xl flex items-center justify-center mb-4">
                    <Users className="w-5 h-5 text-blue-400" />
                  </div>
                  <h3 className="text-lg font-bold text-white mb-1 group-hover:text-blue-300 transition-colors">
                    Partner Accounts
                  </h3>
                  <p className="text-slate-400 text-xs leading-relaxed">
                    Manage referral commissions, partner agencies, and subscription payouts.
                  </p>
                </div>
                <div className="flex items-center gap-2 text-xs font-semibold text-blue-400 mt-4">
                  <span>Explore Partners</span>
                  <ArrowRight className="w-3.5 h-3.5 transform group-hover:translate-x-1 transition-transform" />
                </div>
              </div>

            </div>
          </div>

          {/* System Timeline / Alerts Log */}
          <div className="flex flex-col gap-6">
            <h2 className="text-xl font-bold text-white flex items-center gap-2">
              <Clock className="w-5 h-5 text-indigo-400" /> Live System Logs
            </h2>

            <div className="glass-panel p-6 rounded-2xl flex-1 flex flex-col gap-5">
              
              <div className="flex gap-3 items-start border-b border-white/5 pb-3">
                <div className="w-2.5 h-2.5 rounded-full bg-rose-500 mt-1.5 animate-ping shrink-0" />
                <div>
                  <p className="text-xs font-semibold text-white">Emergency SOS Triggered</p>
                  <p className="text-[11px] text-slate-400 mt-0.5">Driver #8291 • Bangalore East • Flat tyre</p>
                  <span className="inline-block mt-2 px-2 py-0.5 text-[10px] font-medium bg-rose-500/10 text-rose-400 rounded">
                    Towing Dispatched
                  </span>
                </div>
              </div>

              <div className="flex gap-3 items-start border-b border-white/5 pb-3">
                <div className="w-2.5 h-2.5 rounded-full bg-blue-500 mt-1.5 shrink-0" />
                <div>
                  <p className="text-xs font-semibold text-white">Payment Verified</p>
                  <p className="text-[11px] text-slate-400 mt-0.5">Driver #1128 purchased Basic Gold (₹2,499)</p>
                  <span className="inline-block mt-2 px-2 py-0.5 text-[10px] font-medium bg-emerald-500/10 text-emerald-400 rounded">
                    Razorpay Success
                  </span>
                </div>
              </div>

              <div className="flex gap-3 items-start border-b border-white/5 pb-3">
                <div className="w-2.5 h-2.5 rounded-full bg-amber-500 mt-1.5 shrink-0" />
                <div>
                  <p className="text-xs font-semibold text-white">KYC Document Submitted</p>
                  <p className="text-[11px] text-slate-400 mt-0.5">Aadhaar & DL • Driver #4920</p>
                  <span className="inline-block mt-2 px-2 py-0.5 text-[10px] font-medium bg-amber-500/10 text-amber-400 rounded">
                    Pending Review
                  </span>
                </div>
              </div>

              <div className="flex gap-3 items-start">
                <div className="w-2.5 h-2.5 rounded-full bg-emerald-500 mt-1.5 shrink-0" />
                <div>
                  <p className="text-xs font-semibold text-white">Technician Reached Location</p>
                  <p className="text-[11px] text-slate-400 mt-0.5">Job #431 • Replaced battery for Taxi #KA51-2810</p>
                  <span className="inline-block mt-2 px-2 py-0.5 text-[10px] font-medium bg-emerald-500/10 text-emerald-400 rounded">
                    Job Resolved
                  </span>
                </div>
              </div>

            </div>
          </div>

        </div>

      </main>

      {/* Footer */}
      <footer className="mt-auto py-6 border-t border-white/5 text-center text-xs text-slate-500">
        <p>&copy; {new Date().getFullYear()} Erina Assistance Platform. All rights reserved.</p>
      </footer>

    </div>
  );
}
