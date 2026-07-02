import React from "react";
import Link from "next/link";
import { 
  Shield, 
  Truck, 
  Wrench, 
  MapPin, 
  HelpCircle, 
  Sparkles,
  ArrowRight,
  Zap,
  Check,
  FileText,
  Smartphone,
  CheckCircle2
} from "lucide-react";

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen bg-[#020617] text-slate-100 font-sans overflow-x-hidden selection:bg-blue-500/30 selection:text-blue-200">
      
      {/* Background Glows */}
      <div className="absolute top-0 left-1/4 w-[500px] h-[500px] bg-blue-500/10 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute top-[800px] right-1/4 w-[400px] h-[400px] bg-indigo-500/5 rounded-full blur-[100px] pointer-events-none" />

      {/* Navigation */}
      <header className="sticky top-0 z-50 glass-panel border-b border-white/5 py-4 px-6 md:px-12 flex justify-between items-center">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-blue-600/20 border border-blue-500/30 rounded-xl">
            <Shield className="w-6 h-6 text-blue-400" />
          </div>
          <span className="text-xl font-bold tracking-tight text-white font-sans">
            ERINA<span className="text-blue-400 font-light">.assistance</span>
          </span>
        </div>

        <nav className="hidden md:flex items-center gap-8 text-sm font-medium text-slate-300">
          <a href="#services" className="hover:text-white transition-colors">Services</a>
          <a href="#pricing" className="hover:text-white transition-colors">Pricing</a>
          <a href="#faq" className="hover:text-white transition-colors">FAQs</a>
        </nav>

        <div className="flex items-center gap-4">
          <Link 
            href="/login" 
            className="glow-button px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl text-sm transition-all duration-300"
          >
            Access Portal Gateway
          </Link>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative pt-20 pb-16 px-6 md:px-12 max-w-7xl mx-auto flex flex-col items-center text-center gap-6">
        <div className="px-3 py-1 text-xs font-semibold bg-blue-500/10 border border-blue-500/20 text-blue-400 rounded-full flex items-center gap-1.5 animate-pulse">
          <Sparkles className="w-3.5 h-3.5" />
          <span>India's Most Trusted 24/7 Roadside Assistance</span>
        </div>

        <h1 className="text-4xl md:text-6xl font-extrabold tracking-tight text-white max-w-4xl leading-tight">
          Reliable Roadside Assistance & <br/>
          <span className="gradient-text">Fleet Subscription Plans</span>
        </h1>

        <p className="text-slate-400 text-base md:text-lg max-w-2xl leading-relaxed">
          Affordable subscription coverage for commercial drivers, logistics fleets, and independent vehicle owners. Guaranteed technician dispatch in 15 minutes.
        </p>

        <div className="flex flex-col sm:flex-row gap-4 mt-4 w-full justify-center">
          <a 
            href="#pricing" 
            className="px-6 py-3.5 bg-slate-900 border border-white/10 hover:border-blue-500/50 hover:bg-slate-950 text-white font-semibold rounded-xl text-sm transition-all duration-300 flex items-center justify-center gap-2"
          >
            Explore Pricing Plans
          </a>
          <Link 
            href="/login" 
            className="glow-button px-6 py-3.5 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl text-sm transition-all duration-300 flex items-center justify-center gap-2"
          >
            Sign In to Dashboard
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>

        {/* Feature Highlights Row */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6 w-full max-w-5xl mt-16 border-t border-white/5 pt-10">
          <div className="flex flex-col items-center gap-1">
            <span className="text-2xl font-bold text-white">15 Min</span>
            <span className="text-xs text-slate-500 uppercase tracking-wider">Average Dispatch</span>
          </div>
          <div className="flex flex-col items-center gap-1">
            <span className="text-2xl font-bold text-white">12,000+</span>
            <span className="text-xs text-slate-500 uppercase tracking-wider">Active Drivers</span>
          </div>
          <div className="flex flex-col items-center gap-1">
            <span className="text-2xl font-bold text-white">24/7/365</span>
            <span className="text-xs text-slate-500 uppercase tracking-wider">On-demand Support</span>
          </div>
          <div className="flex flex-col items-center gap-1">
            <span className="text-2xl font-bold text-white">98%</span>
            <span className="text-xs text-slate-500 uppercase tracking-wider">CSAT Rating</span>
          </div>
        </div>
      </section>

      {/* Services Section */}
      <section id="services" className="py-20 px-6 md:px-12 max-w-7xl mx-auto w-full border-t border-white/5">
        <div className="text-center max-w-2xl mx-auto mb-16 flex flex-col items-center gap-2">
          <h2 className="text-3xl font-bold text-white">On-Demand Roadside Services</h2>
          <p className="text-slate-400 text-sm leading-relaxed">
            Our comprehensive fleet network delivers dynamic, real-time emergency services directly to your breakdown coordinates.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          
          <div className="glass-panel premium-card p-6 rounded-2xl">
            <div className="w-10 h-10 bg-blue-500/10 rounded-xl flex items-center justify-center mb-6">
              <Truck className="w-5 h-5 text-blue-400" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2">Flat Towing Services</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              Safe hydraulic flatbed and crane towing for vehicles involved in major engine breakdowns or highway collisions.
            </p>
          </div>

          <div className="glass-panel premium-card p-6 rounded-2xl">
            <div className="w-10 h-10 bg-teal-500/10 rounded-xl flex items-center justify-center mb-6">
              <Zap className="w-5 h-5 text-teal-400" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2">Battery & Jumpstart</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              Instant mobile battery diagnostic testing, roadside jumpstarting, and warranty battery delivery.
            </p>
          </div>

          <div className="glass-panel premium-card p-6 rounded-2xl">
            <div className="w-10 h-10 bg-indigo-500/10 rounded-xl flex items-center justify-center mb-6">
              <Wrench className="w-5 h-5 text-indigo-400" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2">Mechanical Diagnostics</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              Roadside fixes for starter motors, cooling systems, brake bleeding, and minor electrical fuses.
            </p>
          </div>

          <div className="glass-panel premium-card p-6 rounded-2xl">
            <div className="w-10 h-10 bg-amber-500/10 rounded-xl flex items-center justify-center mb-6">
              <FileText className="w-5 h-5 text-amber-400" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2">Compliance & KYC</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              Digital tracking of Driving Licenses, RC cards, and insurance, with automated renewal reminder notifications.
            </p>
          </div>

        </div>
      </section>

      {/* Subscription Pricing */}
      <section id="pricing" className="py-20 px-6 md:px-12 bg-slate-950/40 border-y border-white/5 w-full">
        <div className="max-w-7xl mx-auto flex flex-col gap-16">
          <div className="text-center max-w-2xl mx-auto flex flex-col items-center gap-2">
            <h2 className="text-3xl font-bold text-white">Subscription Packages</h2>
            <p className="text-slate-400 text-sm leading-relaxed">
              Decoupled annual coverage designed specifically for Ola, Uber, logistics fleets, and independent vehicle owners.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            
            {/* Silver Plan */}
            <div className="glass-panel premium-card p-8 rounded-3xl flex flex-col justify-between h-[520px]">
              <div>
                <span className="text-slate-400 text-xs uppercase tracking-wider font-semibold">Basic Care</span>
                <h3 className="text-2xl font-bold text-white mt-1">Silver Plan</h3>
                <div className="flex items-baseline gap-1 mt-4">
                  <span className="text-4xl font-extrabold text-white">₹1,499</span>
                  <span className="text-slate-400 text-sm">/ year</span>
                </div>
                <p className="text-slate-400 text-xs mt-4">
                  Ideal for independent taxis operating locally in standard city bounds.
                </p>
                <ul className="flex flex-col gap-3 mt-8 text-xs text-slate-300">
                  <li className="flex items-center gap-2.5">
                    <Check className="w-4 h-4 text-emerald-400 shrink-0" />
                    <span>2 Flatbed Towing jobs (up to 15km)</span>
                  </li>
                  <li className="flex items-center gap-2.5">
                    <Check className="w-4 h-4 text-emerald-400 shrink-0" />
                    <span>Unlimited battery jumpstarts</span>
                  </li>
                  <li className="flex items-center gap-2.5">
                    <Check className="w-4 h-4 text-emerald-400 shrink-0" />
                    <span>Flat tyre replacement support</span>
                  </li>
                  <li className="flex items-center gap-2.5">
                    <Check className="w-4 h-4 text-emerald-400 shrink-0" />
                    <span>15 min dispatcher response</span>
                  </li>
                </ul>
              </div>
              <Link 
                href="/login?plan=silver" 
                className="mt-8 py-3 bg-slate-900 hover:bg-slate-950 border border-white/5 text-center text-sm font-semibold rounded-xl text-white transition-colors"
              >
                Select Silver Plan
              </Link>
            </div>

            {/* Gold Plan */}
            <div className="glass-panel premium-card border-blue-500/30 p-8 rounded-3xl flex flex-col justify-between h-[540px] relative lg:-translate-y-4">
              <div className="absolute -top-3 right-6 px-3 py-1 bg-blue-600 text-white text-[10px] font-bold rounded-full uppercase tracking-wider">
                Most Popular
              </div>
              <div>
                <span className="text-blue-400 text-xs uppercase tracking-wider font-semibold">Premium Cover</span>
                <h3 className="text-2xl font-bold text-white mt-1">Gold Plan</h3>
                <div className="flex items-baseline gap-1 mt-4">
                  <span className="text-4xl font-extrabold text-white">₹2,499</span>
                  <span className="text-slate-400 text-sm">/ year</span>
                </div>
                <p className="text-slate-400 text-xs mt-4">
                  Best value package for active commercial cabs, logistics drivers, and daily fleets.
                </p>
                <ul className="flex flex-col gap-3 mt-8 text-xs text-slate-300">
                  <li className="flex items-center gap-2.5">
                    <Check className="w-4 h-4 text-blue-400 shrink-0" />
                    <span>5 Flatbed/Crane Towing jobs (up to 30km)</span>
                  </li>
                  <li className="flex items-center gap-2.5">
                    <Check className="w-4 h-4 text-blue-400 shrink-0" />
                    <span>Unlimited battery diagnostics & jumpstart</span>
                  </li>
                  <li className="flex items-center gap-2.5">
                    <Check className="w-4 h-4 text-blue-400 shrink-0" />
                    <span>Unlimited roadside mechanical support</span>
                    <span className="px-1.5 py-0.5 text-[8px] bg-blue-500/20 text-blue-300 rounded font-semibold">Free</span>
                  </li>
                  <li className="flex items-center gap-2.5">
                    <Check className="w-4 h-4 text-blue-400 shrink-0" />
                    <span>Driver smart document wallet + compliance tracking</span>
                  </li>
                </ul>
              </div>
              <Link 
                href="/login?plan=gold" 
                className="glow-button mt-8 py-3 bg-blue-600 hover:bg-blue-700 text-center text-sm font-semibold rounded-xl text-white transition-colors"
              >
                Select Gold Plan
              </Link>
            </div>

            {/* Platinum Plan */}
            <div className="glass-panel premium-card p-8 rounded-3xl flex flex-col justify-between h-[520px]">
              <div>
                <span className="text-slate-400 text-xs uppercase tracking-wider font-semibold">Enterprise Protection</span>
                <h3 className="text-2xl font-bold text-white mt-1">Platinum Plan</h3>
                <div className="flex items-baseline gap-1 mt-4">
                  <span className="text-4xl font-extrabold text-white">₹4,999</span>
                  <span className="text-slate-400 text-sm">/ year</span>
                </div>
                <p className="text-slate-400 text-xs mt-4">
                  Complete logistics protection with vehicle downtime guarantee.
                </p>
                <ul className="flex flex-col gap-3 mt-8 text-xs text-slate-300">
                  <li className="flex items-center gap-2.5">
                    <Check className="w-4 h-4 text-emerald-400 shrink-0" />
                    <span>Unlimited Towing (No distance restrictions)</span>
                  </li>
                  <li className="flex items-center gap-2.5">
                    <Check className="w-4 h-4 text-emerald-400 shrink-0" />
                    <span>Free roadside battery replacement</span>
                  </li>
                  <li className="flex items-center gap-2.5">
                    <Check className="w-4 h-4 text-emerald-400 shrink-0" />
                    <span>Dedicated dispatcher + live tracking links</span>
                  </li>
                  <li className="flex items-center gap-2.5">
                    <Check className="w-4 h-4 text-emerald-400 shrink-0" />
                    <span>Full Fleet portal tracking & dashboard analytics</span>
                  </li>
                </ul>
              </div>
              <Link 
                href="/login?plan=platinum" 
                className="mt-8 py-3 bg-slate-900 hover:bg-slate-950 border border-white/5 text-center text-sm font-semibold rounded-xl text-white transition-colors"
              >
                Select Platinum Plan
              </Link>
            </div>

          </div>
        </div>
      </section>

      {/* FAQ Section */}
      <section id="faq" className="py-20 px-6 md:px-12 max-w-5xl mx-auto w-full">
        <div className="text-center max-w-2xl mx-auto mb-16 flex flex-col items-center gap-2">
          <h2 className="text-3xl font-bold text-white">Frequently Asked Questions</h2>
          <p className="text-slate-400 text-sm leading-relaxed">
            Get quick answers regarding subscription coverage boundaries, onboarding rules, and fleet tools.
          </p>
        </div>

        <div className="flex flex-col gap-4">
          
          <div className="glass-panel p-6 rounded-2xl flex gap-4">
            <HelpCircle className="w-6 h-6 text-blue-400 shrink-0 mt-0.5" />
            <div>
              <h3 className="font-bold text-white text-base">How does driver document tracking work?</h3>
              <p className="text-slate-400 text-xs mt-2 leading-relaxed">
                Drivers upload their Driving Licenses, RC cards, and insurance policy papers. The backend parses dates and runs automated verification queries to send push alerts 15 days before any compliance expiry.
              </p>
            </div>
          </div>

          <div className="glass-panel p-6 rounded-2xl flex gap-4">
            <HelpCircle className="w-6 h-6 text-blue-400 shrink-0 mt-0.5" />
            <div>
              <h3 className="font-bold text-white text-base">Can a Fleet Owner manage multiple vehicle subscriptions?</h3>
              <p className="text-slate-400 text-xs mt-2 leading-relaxed">
                Yes. Through the Fleet Portal, operators can register up to 500 cabs/trucks, buy bulk packages with enterprise discounts, pair drivers dynamically, and inspect liveness metrics.
              </p>
            </div>
          </div>

          <div className="glass-panel p-6 rounded-2xl flex gap-4">
            <HelpCircle className="w-6 h-6 text-blue-400 shrink-0 mt-0.5" />
            <div>
              <h3 className="font-bold text-white text-base">What is the average response time for towing?</h3>
              <p className="text-slate-400 text-xs mt-2 leading-relaxed">
                Once a driver triggers the SOS button on their app, our closest network technician accepts the task. The average ETA to reach the vehicle is 15 minutes inside urban sectors.
              </p>
            </div>
          </div>

        </div>
      </section>

      {/* Footer */}
      <footer className="py-8 border-t border-white/5 text-center text-xs text-slate-500">
        <p>&copy; {new Date().getFullYear()} Erina Assistance Platform. All rights reserved.</p>
      </footer>

    </div>
  );
}
