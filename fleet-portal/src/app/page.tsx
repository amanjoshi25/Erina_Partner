"use client";

import React, { useState, useEffect } from "react";
import { 
  Shield, 
  Users, 
  CheckCircle2, 
  AlertCircle, 
  TrendingUp, 
  MapPin, 
  CreditCard, 
  ArrowRight, 
  Clock, 
  Truck,
  PlusCircle,
  FileText,
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
        localStorage.setItem("fleet_token", urlToken);
      } else {
        const localToken = localStorage.getItem("fleet_token");
        if (localToken) setToken(localToken);
      }
    }
  }, []);

  return (
    <div className="flex flex-col min-h-screen bg-[#011512] text-teal-50 font-sans selection:bg-teal-500/30 selection:text-teal-200">
      
      {/* Background Orbs */}
      <div className="absolute top-0 left-1/4 w-96 h-96 bg-teal-500/5 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute top-1/3 right-1/4 w-96 h-96 bg-emerald-500/5 rounded-full blur-3xl pointer-events-none" />
      
      {/* Header */}
      <header className="sticky top-0 z-50 glass-panel border-b border-teal-500/10 py-4 px-6 md:px-12 flex justify-between items-center">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-teal-600/20 border border-teal-500/30 rounded-xl">
            <Truck className="w-6 h-6 text-teal-400" />
          </div>
          <div>
            <span className="text-xl font-bold tracking-tight text-white font-sans">
              ERINA<span className="text-teal-400 font-light">.fleet</span>
            </span>
            <span className="hidden sm:inline-block ml-3 px-2 py-0.5 text-xs font-semibold bg-teal-500/10 text-teal-300 border border-teal-500/20 rounded-full">
              Vikas Logistics
            </span>
          </div>
        </div>

        <nav className="flex items-center gap-6">
          <div className="flex items-center gap-2 text-sm text-teal-400">
            <span className="w-2.5 h-2.5 bg-teal-400 rounded-full animate-pulse" />
            <span className="hidden md:inline">Active Operations:</span>
            <span className="font-semibold text-teal-300">1 Dispatch Live</span>
          </div>
          <div className="h-4 w-px bg-teal-900" />
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-full bg-teal-950 border border-teal-800 flex items-center justify-center font-bold text-teal-400 text-sm">
              VL
            </div>
          </div>
        </nav>
      </header>

      {/* Main Container */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-6 py-10 md:px-12 flex flex-col gap-10">
        
        {token && (
          <div className="flex items-center justify-between p-4 bg-teal-500/10 border border-teal-500/25 text-teal-400 rounded-2xl text-xs gap-3 animate-fade-in">
            <div className="flex items-center gap-2.5">
              <div className="p-1.5 bg-teal-500/10 rounded-lg">
                <Unlock className="w-4 h-4 text-teal-400 shrink-0" />
              </div>
              <div>
                <span className="font-bold uppercase tracking-wider block text-[10px]">Single-Sign-On Verified</span>
                <span className="text-teal-300 font-mono text-[10px] truncate max-w-md block mt-0.5">Session Token: {token}</span>
              </div>
            </div>
            <button 
              onClick={() => {
                localStorage.removeItem("fleet_token");
                window.location.href = "http://localhost:3000/login";
              }}
              className="px-3 py-1.5 bg-[#012620] hover:bg-[#011a16] border border-white/5 text-slate-300 font-semibold rounded-lg hover:text-red-400 transition-colors cursor-pointer"
            >
              Sign out
            </button>
          </div>
        )}

        {/* Title and Intro */}
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-3xl md:text-4xl font-extrabold tracking-tight text-white mb-2">
              Fleet Control Console
            </h1>
            <p className="text-teal-400/70 text-base max-w-2xl">
              Monitor active commercial vehicles, manage subscription health, and track roadside assistance incidents.
            </p>
          </div>
          <button className="glow-button flex items-center justify-center gap-2 px-5 py-3 bg-teal-600 hover:bg-teal-700 text-white font-semibold rounded-xl text-sm transition-all duration-300">
            <PlusCircle className="w-4 h-4" />
            Add New Vehicle
          </button>
        </div>

        {/* Dashboard Grid - Stats */}
        <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          
          <div className="glass-panel premium-card p-6 rounded-2xl">
            <div className="flex items-center justify-between mb-4">
              <span className="text-sm font-medium text-teal-400">Fleet Size</span>
              <div className="p-2 bg-teal-500/10 rounded-lg">
                <Truck className="w-5 h-5 text-teal-400" />
              </div>
            </div>
            <h3 className="text-2xl font-bold text-white mb-1">142</h3>
            <div className="flex items-center gap-1.5 text-xs text-teal-400">
              <span>Vehicles registered</span>
            </div>
          </div>

          <div className="glass-panel premium-card p-6 rounded-2xl">
            <div className="flex items-center justify-between mb-4">
              <span className="text-sm font-medium text-teal-400">Covered Subscriptions</span>
              <div className="p-2 bg-emerald-500/10 rounded-lg">
                <CheckCircle2 className="w-5 h-5 text-emerald-400" />
              </div>
            </div>
            <h3 className="text-2xl font-bold text-white mb-1">128</h3>
            <div className="flex items-center gap-1.5 text-xs text-emerald-400">
              <TrendingUp className="w-3.5 h-3.5" />
              <span>90% coverage level</span>
            </div>
          </div>

          <div className="glass-panel premium-card p-6 rounded-2xl">
            <div className="flex items-center justify-between mb-4">
              <span className="text-sm font-medium text-teal-400">Uncovered (Needs Plan)</span>
              <div className="p-2 bg-amber-500/10 rounded-lg">
                <AlertCircle className="w-5 h-5 text-amber-400" />
              </div>
            </div>
            <h3 className="text-2xl font-bold text-white mb-1">14</h3>
            <div className="flex items-center gap-1.5 text-xs text-amber-400">
              <span>Urgent action recommended</span>
            </div>
          </div>

          <div className="glass-panel premium-card p-6 rounded-2xl">
            <div className="flex items-center justify-between mb-4">
              <span className="text-sm font-medium text-teal-400">Active Incidents</span>
              <div className="p-2 bg-rose-500/10 rounded-lg">
                <MapPin className="w-5 h-5 text-rose-400" />
              </div>
            </div>
            <h3 className="text-2xl font-bold text-white mb-1">1</h3>
            <div className="flex items-center gap-1.5 text-xs text-rose-400">
              <Clock className="w-3.5 h-3.5" />
              <span>ETA: 12 mins</span>
            </div>
          </div>

        </section>

        {/* Dynamic Panels */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          
          {/* Quick Action Navigation Grid */}
          <div className="lg:col-span-2 flex flex-col gap-6">
            <h2 className="text-xl font-bold text-white flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-teal-400" /> Fleet Actions
            </h2>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              
              <div className="glass-panel premium-card p-6 rounded-2xl flex flex-col justify-between h-52 group cursor-pointer">
                <div>
                  <div className="w-10 h-10 bg-teal-500/10 rounded-xl flex items-center justify-center mb-4">
                    <PlusCircle className="w-5 h-5 text-teal-400" />
                  </div>
                  <h3 className="text-lg font-bold text-white mb-1 group-hover:text-teal-300 transition-colors">
                    Add New Vehicle
                  </h3>
                  <p className="text-teal-400/60 text-xs leading-relaxed">
                    Upload RC copy and register commercial cabs or trucks to link with active subscription benefits.
                  </p>
                </div>
                <div className="flex items-center gap-2 text-xs font-semibold text-teal-400 mt-4">
                  <span>Go to Registration</span>
                  <ArrowRight className="w-3.5 h-3.5 transform group-hover:translate-x-1 transition-transform" />
                </div>
              </div>

              <div className="glass-panel premium-card p-6 rounded-2xl flex flex-col justify-between h-52 group cursor-pointer">
                <div>
                  <div className="w-10 h-10 bg-emerald-500/10 rounded-xl flex items-center justify-center mb-4">
                    <CreditCard className="w-5 h-5 text-emerald-400" />
                  </div>
                  <h3 className="text-lg font-bold text-white mb-1 group-hover:text-emerald-300 transition-colors">
                    Bulk Subscriptions
                  </h3>
                  <p className="text-teal-400/60 text-xs leading-relaxed">
                    Purchase or renew annual roadside assistance coverage plans for multiple vehicles with fleet discounts.
                  </p>
                </div>
                <div className="flex items-center gap-2 text-xs font-semibold text-emerald-400 mt-4">
                  <span>Manage Plans</span>
                  <ArrowRight className="w-3.5 h-3.5 transform group-hover:translate-x-1 transition-transform" />
                </div>
              </div>

              <div className="glass-panel premium-card p-6 rounded-2xl flex flex-col justify-between h-52 group cursor-pointer">
                <div>
                  <div className="w-10 h-10 bg-indigo-500/10 rounded-xl flex items-center justify-center mb-4">
                    <Users className="w-5 h-5 text-indigo-400" />
                  </div>
                  <h3 className="text-lg font-bold text-white mb-1 group-hover:text-indigo-300 transition-colors">
                    Driver Allocation
                  </h3>
                  <p className="text-teal-400/60 text-xs leading-relaxed">
                    Assign drivers to active vehicles and monitor their driving license expiry, training, and KYC status.
                  </p>
                </div>
                <div className="flex items-center gap-2 text-xs font-semibold text-indigo-400 mt-4">
                  <span>View Assignments</span>
                  <ArrowRight className="w-3.5 h-3.5 transform group-hover:translate-x-1 transition-transform" />
                </div>
              </div>

              <div className="glass-panel premium-card p-6 rounded-2xl flex flex-col justify-between h-52 group cursor-pointer">
                <div>
                  <div className="w-10 h-10 bg-teal-500/10 rounded-xl flex items-center justify-center mb-4">
                    <FileText className="w-5 h-5 text-teal-400" />
                  </div>
                  <h3 className="text-lg font-bold text-white mb-1 group-hover:text-teal-300 transition-colors">
                    Incidents & Reports
                  </h3>
                  <p className="text-teal-400/60 text-xs leading-relaxed">
                    Review history of towing/battery/mechanic service requests and download fleet downtime logs.
                  </p>
                </div>
                <div className="flex items-center gap-2 text-xs font-semibold text-teal-400 mt-4">
                  <span>Download Reports</span>
                  <ArrowRight className="w-3.5 h-3.5 transform group-hover:translate-x-1 transition-transform" />
                </div>
              </div>

            </div>
          </div>

          {/* Fleet Timeline Alerts */}
          <div className="flex flex-col gap-6">
            <h2 className="text-xl font-bold text-white flex items-center gap-2">
              <Clock className="w-5 h-5 text-teal-400" /> Fleet Alerts
            </h2>

            <div className="glass-panel p-6 rounded-2xl flex-1 flex flex-col gap-5">
              
              <div className="flex gap-3 items-start border-b border-teal-500/5 pb-3">
                <div className="w-2.5 h-2.5 rounded-full bg-rose-500 mt-1.5 animate-ping shrink-0" />
                <div>
                  <p className="text-xs font-semibold text-white">Live RSA Dispatch</p>
                  <p className="text-[11px] text-teal-400/80 mt-0.5">Vehicle: KA-51-MJ-2200 (Ola cab)</p>
                  <p className="text-[11px] text-teal-400/80">Issue: Starter Motor failure • Bellandur</p>
                  <span className="inline-block mt-2 px-2 py-0.5 text-[10px] font-medium bg-rose-500/10 text-rose-400 rounded">
                    Towing in progress (12m ETA)
                  </span>
                </div>
              </div>

              <div className="flex gap-3 items-start border-b border-teal-500/5 pb-3">
                <div className="w-2.5 h-2.5 rounded-full bg-amber-500 mt-1.5 shrink-0" />
                <div>
                  <p className="text-xs font-semibold text-white">DL Expiring Soon</p>
                  <p className="text-[11px] text-teal-400/80 mt-0.5">Driver: Ramesh Sharma (Cab KA-51-MJ-2800)</p>
                  <span className="inline-block mt-2 px-2 py-0.5 text-[10px] font-medium bg-amber-500/10 text-amber-300 rounded">
                    Expires in 4 days
                  </span>
                </div>
              </div>

              <div className="flex gap-3 items-start border-b border-teal-500/5 pb-3">
                <div className="w-2.5 h-2.5 rounded-full bg-teal-500 mt-1.5 shrink-0" />
                <div>
                  <p className="text-xs font-semibold text-white">Subscription Auto-Renewed</p>
                  <p className="text-[11px] text-teal-400/80 mt-0.5">Vehicle: KA-03-PL-8899 (Truck)</p>
                  <span className="inline-block mt-2 px-2 py-0.5 text-[10px] font-medium bg-emerald-500/10 text-emerald-400 rounded">
                    Gold Plan Renewed
                  </span>
                </div>
              </div>

              <div className="flex gap-3 items-start">
                <div className="w-2.5 h-2.5 rounded-full bg-rose-400 mt-1.5 shrink-0" />
                <div>
                  <p className="text-xs font-semibold text-white">Unsubscribed Vehicles</p>
                  <p className="text-[11px] text-teal-400/80 mt-0.5">14 recently imported vehicles are not covered.</p>
                  <span className="inline-block mt-2 px-2 py-0.5 text-[10px] font-medium bg-rose-500/10 text-rose-300 rounded">
                    No active protection
                  </span>
                </div>
              </div>

            </div>
          </div>

        </div>

      </main>

      {/* Footer */}
      <footer className="mt-auto py-6 border-t border-teal-500/10 text-center text-xs text-teal-600">
        <p>&copy; {new Date().getFullYear()} Erina Assistance Platform - Fleet Console. All rights reserved.</p>
      </footer>

    </div>
  );
}
