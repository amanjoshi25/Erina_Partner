"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { 
  Shield, 
  ArrowLeft, 
  ChevronRight, 
  Lock, 
  Smartphone, 
  CheckCircle2, 
  AlertCircle, 
  LogOut, 
  Users, 
  Truck, 
  Wrench, 
  Award,
  Wallet,
  MapPin
} from "lucide-react";

export default function Login() {
  const [role, setRole] = useState("driver"); // default role selection
  const [mobileNumber, setMobileNumber] = useState("");
  const [otp, setOtp] = useState("");
  const [debugOtp, setDebugOtp] = useState("");
  const [step, setStep] = useState<"phone" | "otp" | "authenticated">("phone");
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  
  // Authenticated state parameters
  const [accessToken, setAccessToken] = useState("");
  const [backendRole, setBackendRole] = useState("");
  const [isKycVerified, setIsKycVerified] = useState(false);

  // Auto-redirect operations
  useEffect(() => {
    if (step === "authenticated") {
      if (backendRole === "Admin" || backendRole === "Operations") {
        const timer = setTimeout(() => {
          window.location.href = `http://localhost:3001/?token=${accessToken}&role=${backendRole}`;
        }, 2000);
        return () => clearTimeout(timer);
      } else if (backendRole === "Fleet Owner") {
        const timer = setTimeout(() => {
          window.location.href = `http://localhost:3002/?token=${accessToken}&role=${backendRole}`;
        }, 2000);
        return () => clearTimeout(timer);
      }
    }
  }, [step, backendRole, accessToken]);

  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setErrorMessage("");

    try {
      const response = await fetch("http://localhost:8000/api/v1/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: jsonStringify({ mobile_number: mobileNumber.trim() })
      });
      const data = await response.json();

      if (response.ok) {
        setStep("otp");
        if (data.debug_code) {
          setDebugOtp(data.debug_code);
          setOtp(data.debug_code); // Dev prefill for convenience
        }
      } else {
        setErrorMessage(data.detail || "Failed to trigger verification code");
      }
    } catch (err) {
      setErrorMessage("Network error: Make sure FastAPI backend (port 8000) is running.");
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setErrorMessage("");

    try {
      const response = await fetch("http://localhost:8000/api/v1/auth/verify-otp", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: jsonStringify({
          mobile_number: mobileNumber.trim(),
          otp: otp.trim(),
          role: role, // Sent so database automatically creates this role if new user
          device_info: "Next.js Unified Web Gateway"
        })
      });
      const data = await response.json();

      if (response.ok) {
        setAccessToken(data.access_token);
        setBackendRole(data.role);
        setIsKycVerified(data.is_kyc_verified);
        setStep("authenticated");
      } else {
        setErrorMessage(data.detail || "Invalid verification code");
      }
    } catch (err) {
      setErrorMessage("Verification error. Please retry.");
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = () => {
    setStep("phone");
    setMobileNumber("");
    setOtp("");
    setDebugOtp("");
    setAccessToken("");
    setBackendRole("");
  };

  function jsonStringify(obj: any) {
    return JSON.stringify(obj);
  }

  // --- Rendering Functions ---

  const renderPhoneStep = () => (
    <form onSubmit={handleSendOtp} className="flex flex-col gap-5">
      <div className="flex flex-col gap-2">
        <label className="text-xs font-semibold text-slate-300">Access Role Select</label>
        <div className="relative">
          <select
            value={role}
            onChange={(e) => setRole(e.target.value)}
            className="w-full bg-[#0b1329] border border-white/10 rounded-xl px-4 py-3.5 text-sm text-white focus:outline-none focus:border-blue-500 transition-colors appearance-none cursor-pointer"
          >
            <option value="driver">Commercial Driver Portal (App)</option>
            <option value="partner">Referral Partner Portal (Agency)</option>
            <option value="fleet">Fleet Owner / Operator Panel</option>
            <option value="admin">Operations Administrator (Admin)</option>
            <option value="technician">Roadside Technician (Responder)</option>
          </select>
          <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400 text-[10px]">
            ▼
          </div>
        </div>
      </div>

      <div className="flex flex-col gap-2">
        <label className="text-xs font-semibold text-slate-300">Mobile Phone Number</label>
        <div className="relative">
          <input
            type="tel"
            required
            value={mobileNumber}
            onChange={(e) => setMobileNumber(e.target.value)}
            placeholder="e.g. +91 9988776655"
            className="w-full bg-[#0b1329] border border-white/10 rounded-xl pl-10 pr-4 py-3.5 text-sm text-white placeholder:text-slate-500 focus:outline-none focus:border-blue-500 transition-colors"
          />
          <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500">
            <Smartphone className="w-4 h-4" />
          </div>
        </div>
      </div>

      {errorMessage && (
        <div className="flex items-center gap-2 p-3 bg-red-500/10 border border-red-500/20 text-red-400 rounded-xl text-xs">
          <AlertCircle className="w-4 h-4 shrink-0" />
          <span>{errorMessage}</span>
        </div>
      )}

      <button
        type="submit"
        disabled={loading}
        className="glow-button mt-2 w-full py-3.5 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl text-sm transition-all duration-300 flex items-center justify-center gap-2 cursor-pointer"
      >
        {loading ? (
          <span className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
        ) : (
          <>
            <span>Request Authentication OTP</span>
            <ChevronRight className="w-4 h-4" />
          </>
        )}
      </button>
    </form>
  );

  const renderOtpStep = () => (
    <form onSubmit={handleVerifyOtp} className="flex flex-col gap-5">
      <div className="flex flex-col gap-1 text-center bg-blue-500/5 border border-blue-500/10 rounded-2xl p-4 mb-2">
        <span className="text-xs text-blue-400 font-semibold">Verification Code Issued</span>
        <span className="text-[10px] text-slate-400">Mock SMS sent to {mobileNumber}</span>
        {debugOtp && (
          <div className="mt-2 text-xs font-mono bg-blue-600/15 border border-blue-500/20 text-blue-300 py-1.5 px-3 rounded-lg flex items-center justify-center gap-2">
            <span>Dev Code:</span>
            <span className="font-bold tracking-widest">{debugOtp}</span>
          </div>
        )}
      </div>

      <div className="flex flex-col gap-2">
        <label className="text-xs font-semibold text-slate-300">6-Digit OTP Code</label>
        <div className="relative">
          <input
            type="text"
            maxLength={6}
            required
            value={otp}
            onChange={(e) => setOtp(e.target.value)}
            placeholder="Enter verification code"
            className="w-full bg-[#0b1329] border border-white/10 rounded-xl pl-10 pr-4 py-3.5 text-sm text-white placeholder:text-slate-500 focus:outline-none focus:border-blue-500 transition-colors text-center tracking-widest font-bold"
          />
          <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500">
            <Lock className="w-4 h-4" />
          </div>
        </div>
      </div>

      {errorMessage && (
        <div className="flex items-center gap-2 p-3 bg-red-500/10 border border-red-500/20 text-red-400 rounded-xl text-xs">
          <AlertCircle className="w-4 h-4 shrink-0" />
          <span>{errorMessage}</span>
        </div>
      )}

      <div className="flex gap-3">
        <button
          type="button"
          onClick={() => setStep("phone")}
          className="flex-1 py-3.5 bg-slate-900 border border-white/10 hover:bg-slate-950 font-semibold rounded-xl text-sm text-white transition-colors cursor-pointer text-center"
        >
          Back
        </button>
        <button
          type="submit"
          disabled={loading}
          className="flex-1 py-3.5 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl text-sm transition-all duration-300 flex items-center justify-center gap-2 cursor-pointer"
        >
          {loading ? (
            <span className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
          ) : (
            <span>Verify & Access</span>
          )}
        </button>
      </div>
    </form>
  );

  const renderDashboardRedirection = () => (
    <div className="flex flex-col items-center justify-center text-center gap-6 py-6">
      <div className="w-16 h-16 bg-emerald-500/15 rounded-full flex items-center justify-center border border-emerald-500/30 animate-pulse">
        <CheckCircle2 className="w-8 h-8 text-emerald-400" />
      </div>
      <div>
        <h3 className="text-xl font-bold text-white mb-2">Login Successful</h3>
        <p className="text-slate-400 text-xs">Verified role: <span className="text-blue-400 font-semibold">{backendRole}</span></p>
      </div>
      
      <div className="w-full bg-slate-950/60 border border-white/5 rounded-2xl p-4 flex flex-col gap-2">
        <span className="text-slate-500 text-[10px] font-bold uppercase tracking-wider">Gateway Redirection</span>
        <p className="text-xs text-slate-300 leading-relaxed">
          Redirecting you to the **{backendRole} Control Console** on port {backendRole === "Admin" ? "3001" : "3002"}...
        </p>
        <div className="w-full bg-white/5 rounded-full h-1.5 overflow-hidden mt-2">
          <div className="bg-emerald-500 h-full w-[80%] rounded-full animate-loading" />
        </div>
      </div>

      <a
        href={backendRole === "Admin" ? `http://localhost:3001/?token=${accessToken}` : `http://localhost:3002/?token=${accessToken}`}
        className="text-xs text-blue-400 underline hover:text-blue-300 transition-colors mt-2"
      >
        Click here if you are not redirected automatically
      </a>
    </div>
  );

  // Inline Dashboards for Drivers / Partners / Technicians
  const renderInlineDashboard = () => {
    if (backendRole === "Partner") {
      return (
        <div className="w-full max-w-4xl glass-panel p-8 md:p-10 rounded-3xl relative animate-fade-in">
          <div className="flex justify-between items-center border-b border-white/5 pb-6 mb-8">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-indigo-500/10 rounded-xl">
                <Users className="w-6 h-6 text-indigo-400" />
              </div>
              <div>
                <h2 className="text-xl font-bold text-white">Partner Agency Dashboard</h2>
                <p className="text-slate-400 text-xs">Code: PRT-2026-X8320 | Agency Status: <span className="text-emerald-400 font-bold">Active</span></p>
              </div>
            </div>
            <button onClick={handleLogout} className="flex items-center gap-1.5 text-xs text-slate-400 hover:text-red-400 transition-colors cursor-pointer border border-white/5 rounded-lg px-3 py-1.5">
              <LogOut className="w-3.5 h-3.5" />
              <span>Log out</span>
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div className="bg-[#0b1329] border border-white/5 p-5 rounded-2xl">
              <span className="text-slate-500 text-[10px] font-bold uppercase tracking-wider">Referral Code</span>
              <h3 className="text-lg font-bold text-white mt-1 select-all font-mono">ERINAPRT-10</h3>
              <p className="text-slate-400 text-[10px] mt-1">10% commission on subscriptions</p>
            </div>
            <div className="bg-[#0b1329] border border-white/5 p-5 rounded-2xl">
              <span className="text-slate-500 text-[10px] font-bold uppercase tracking-wider">Referred Drivers</span>
              <h3 className="text-2xl font-black text-white mt-1">42 Taxis</h3>
              <p className="text-emerald-400 text-[10px] mt-1">▲ +8 new this week</p>
            </div>
            <div className="bg-[#0b1329] border border-white/5 p-5 rounded-2xl">
              <span className="text-slate-500 text-[10px] font-bold uppercase tracking-wider">Earnings Balance</span>
              <h3 className="text-2xl font-black text-indigo-400 mt-1">₹12,490.00</h3>
              <p className="text-slate-400 text-[10px] mt-1">Next payout: July 15, 2026</p>
            </div>
          </div>

          <div className="bg-slate-950/40 border border-white/5 rounded-2xl p-6">
            <h4 className="text-sm font-bold text-white mb-4">Referred Customer Pipelines</h4>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="border-b border-white/5 text-slate-500">
                    <th className="py-2.5">Driver Name</th>
                    <th className="py-2.5">Vehicle Model</th>
                    <th className="py-2.5">Plan Type</th>
                    <th className="py-2.5">Payout Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/5 text-slate-300">
                  <tr>
                    <td className="py-3 font-semibold text-white">Suresh Kumar</td>
                    <td className="py-3">Tata Nexon EV</td>
                    <td className="py-3">Gold Plan (₹2,999)</td>
                    <td className="py-3"><span className="px-2 py-0.5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 rounded">Paid</span></td>
                  </tr>
                  <tr>
                    <td className="py-3 font-semibold text-white">Ramesh Patel</td>
                    <td className="py-3">Maruti Dzire</td>
                    <td className="py-3">Silver Plan (₹1,999)</td>
                    <td className="py-3"><span className="px-2 py-0.5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 rounded">Paid</span></td>
                  </tr>
                  <tr>
                    <td className="py-3 font-semibold text-white">Anil M.</td>
                    <td className="py-3">Toyota Etios</td>
                    <td className="py-3">Gold Plan (₹2,999)</td>
                    <td className="py-3"><span className="px-2 py-0.5 bg-amber-500/10 text-amber-400 border border-amber-500/20 rounded">Processing</span></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      );
    }

    if (backendRole === "Driver") {
      return (
        <div className="w-full max-w-4xl glass-panel p-8 md:p-10 rounded-3xl relative animate-fade-in">
          <div className="flex justify-between items-center border-b border-white/5 pb-6 mb-8">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-500/10 rounded-xl">
                <Truck className="w-6 h-6 text-blue-400" />
              </div>
              <div>
                <h2 className="text-xl font-bold text-white">Commercial Driver Web Console</h2>
                <p className="text-slate-400 text-xs">Code: DRV-2026-X9920 | Status: <span className="text-blue-400 font-bold">{isKycVerified ? "KYC Verified" : "KYC Pending"}</span></p>
              </div>
            </div>
            <button onClick={handleLogout} className="flex items-center gap-1.5 text-xs text-slate-400 hover:text-red-400 transition-colors cursor-pointer border border-white/5 rounded-lg px-3 py-1.5">
              <LogOut className="w-3.5 h-3.5" />
              <span>Log out</span>
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div className="bg-[#0b1329] border border-white/5 p-5 rounded-2xl">
              <span className="text-slate-500 text-[10px] font-bold uppercase tracking-wider">Active Vehicle</span>
              <h3 className="text-lg font-bold text-white mt-1">KA-51-MJ-2810</h3>
              <p className="text-slate-400 text-[10px] mt-1">Tata Nexon (Commercial Taxi)</p>
            </div>
            <div className="bg-[#0b1329] border border-white/5 p-5 rounded-2xl">
              <span className="text-slate-500 text-[10px] font-bold uppercase tracking-wider">Assigned Subscription</span>
              <h3 className="text-lg font-bold text-blue-400 mt-1">Gold Coverage Tier</h3>
              <p className="text-slate-400 text-[10px] mt-1">Active until Dec 12, 2026</p>
            </div>
            <div className="bg-[#0b1329] border border-white/5 p-5 rounded-2xl">
              <span className="text-slate-500 text-[10px] font-bold uppercase tracking-wider">Assistance SOS</span>
              <h3 className="text-lg font-bold text-slate-400 mt-1">No Active Incident</h3>
              <p className="text-slate-400 text-[10px] mt-1">Ready for 24/7 dispatcher SOS</p>
            </div>
          </div>

          <div className="bg-slate-950/40 border border-white/5 rounded-2xl p-6 text-center">
            <p className="text-slate-400 text-xs mb-4">
              To trigger emergency roadside help, manage vehicle documents, or make payments, please use the mobile app on the active emulator.
            </p>
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-blue-500/10 border border-blue-500/20 text-blue-400 rounded-xl text-xs">
              <Smartphone className="w-4 h-4" />
              <span>Active Emulator Session: Android gphone64 (emulator-5554)</span>
            </div>
          </div>
        </div>
      );
    }

    if (backendRole === "Technician") {
      return (
        <div className="w-full max-w-4xl glass-panel p-8 md:p-10 rounded-3xl relative animate-fade-in">
          <div className="flex justify-between items-center border-b border-white/5 pb-6 mb-8">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-500/10 rounded-xl">
                <Wrench className="w-6 h-6 text-emerald-400" />
              </div>
              <div>
                <h2 className="text-xl font-bold text-white">Technician Responder Hub</h2>
                <p className="text-slate-400 text-xs">Online Dispatch Status: <span className="text-emerald-400 font-bold">Ready / Standby</span></p>
              </div>
            </div>
            <button onClick={handleLogout} className="flex items-center gap-1.5 text-xs text-slate-400 hover:text-red-400 transition-colors cursor-pointer border border-white/5 rounded-lg px-3 py-1.5">
              <LogOut className="w-3.5 h-3.5" />
              <span>Log out</span>
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
            <div className="bg-[#0b1329] border border-white/5 p-6 rounded-2xl flex items-center justify-between">
              <div>
                <span className="text-slate-500 text-[10px] font-bold uppercase tracking-wider">Responder Name</span>
                <h3 className="text-lg font-bold text-white mt-1">Amit Sharma</h3>
                <p className="text-slate-400 text-[10px] mt-1">ID: TECH-82910 | Bangalore East</p>
              </div>
              <div className="p-3 bg-emerald-500/10 rounded-xl">
                <Award className="w-6 h-6 text-emerald-400" />
              </div>
            </div>
            <div className="bg-[#0b1329] border border-white/5 p-6 rounded-2xl flex items-center justify-between">
              <div>
                <span className="text-slate-500 text-[10px] font-bold uppercase tracking-wider">Incident GPS Grid</span>
                <h3 className="text-lg font-bold text-white mt-1">Latitude: 12.9716</h3>
                <p className="text-slate-400 text-[10px] mt-1">Longitude: 77.5946 (HSR Layout)</p>
              </div>
              <div className="p-3 bg-blue-500/10 rounded-xl">
                <MapPin className="w-6 h-6 text-blue-400" />
              </div>
            </div>
          </div>

          <div className="bg-slate-950/40 border border-white/5 rounded-2xl p-6 text-center">
            <p className="text-slate-400 text-xs">
              When drivers request emergency roadside help, dispatch requests will stream instantly to your mobile responder device.
            </p>
          </div>
        </div>
      );
    }

    return null;
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

      {/* Main Container */}
      <main className="flex-1 flex items-center justify-center py-16 px-6 z-10">
        {step === "authenticated" && (backendRole === "Partner" || backendRole === "Driver" || backendRole === "Technician") ? (
          renderInlineDashboard()
        ) : (
          <div className="w-full max-w-md glass-panel p-8 md:p-10 rounded-3xl relative">
            
            <div className="flex flex-col items-center text-center gap-2 mb-8">
              <div className="w-12 h-12 bg-blue-500/10 rounded-2xl flex items-center justify-center border border-blue-500/20 mb-2">
                <Shield className="w-6 h-6 text-blue-400" />
              </div>
              <h2 className="text-2xl font-extrabold text-white">Unified Portal Access</h2>
              <p className="text-slate-400 text-xs">
                {step === "phone" 
                  ? "Select your role and enter mobile number to receive OTP access."
                  : `Enter verification OTP sent to ${mobileNumber}`
                }
              </p>
            </div>

            {step === "phone" && renderPhoneStep()}
            {step === "otp" && renderOtpStep()}
            {step === "authenticated" && renderDashboardRedirection()}

          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="py-6 border-t border-white/5 text-center text-xs text-slate-500 z-10">
        <p>&copy; {new Date().getFullYear()} Erina Assistance Platform. All rights reserved.</p>
      </footer>

    </div>
  );
}
