import React from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { Calendar, LayoutDashboard, LogOut, User, Building } from "lucide-react";
import { clearUserSession, getCurrentUser, isAuthenticated } from "../utils/api";
import { Button } from "./ui/Button";

export default function Navbar() {
  const location = useLocation();
  const navigate = useNavigate();
  const user = getCurrentUser();
  const authed = isAuthenticated();

  const handleLogout = () => {
    clearUserSession();
    navigate("/signin");
  };

  if (!authed) return null; // Only show navbar when logged in

  const isActive = (path) => location.pathname === path;

  return (
    <nav className="glass sticky top-0 z-50 w-full px-6 py-4 shadow-xl mb-6">
      <div className="max-w-7xl mx-auto flex items-center justify-between">
        {/* Brand/Logo */}
        <Link to="/" className="flex items-center gap-2 group">
          <div className="bg-gradient-to-tr from-indigo-500 to-purple-500 p-2 rounded-lg text-white shadow-lg shadow-indigo-500/10 group-hover:scale-105 transition-transform duration-200">
            <Calendar size={20} className="animate-pulse-slow" />
          </div>
          <div>
            <span className="font-extrabold text-lg bg-gradient-to-r from-white via-indigo-200 to-indigo-400 bg-clip-text text-transparent tracking-wide">
              EMINENCE
            </span>
            <span className="text-xs block text-indigo-400/80 -mt-1 font-semibold tracking-widest">
              EVENTS HUB
            </span>
          </div>
        </Link>

        {/* Navigation Links */}
        <div className="hidden md:flex items-center gap-2 bg-white/5 p-1 rounded-lg border border-white/5">
          <Link
            to="/"
            className={`flex items-center gap-1.5 px-4 py-2 rounded-md text-sm font-medium transition-all duration-200 ${
              isActive("/")
                ? "bg-indigo-600/80 text-white shadow-md shadow-indigo-600/10"
                : "text-gray-400 hover:text-white hover:bg-white/5"
            }`}
          >
            <LayoutDashboard size={16} />
            Registrations
          </Link>
          <Link
            to="/events"
            className={`flex items-center gap-1.5 px-4 py-2 rounded-md text-sm font-medium transition-all duration-200 ${
              isActive("/events")
                ? "bg-indigo-600/80 text-white shadow-md shadow-indigo-600/10"
                : "text-gray-400 hover:text-white hover:bg-white/5"
            }`}
          >
            <Calendar size={16} />
            Events Setup
          </Link>
        </div>

        {/* User Info & Actions */}
        <div className="flex items-center gap-4">
          <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-lg bg-white/5 border border-white/5">
            <User size={14} className="text-indigo-400" />
            <div className="text-left leading-none">
              <span className="text-xs font-semibold text-white block">{user?.fullName}</span>
              {user?.organization && (
                <span className="text-[10px] text-gray-400 font-medium inline-flex items-center gap-0.5 mt-0.5">
                  <Building size={8} /> {user.organization}
                </span>
              )}
            </div>
          </div>

          <Button
            variant="ghost"
            size="sm"
            onClick={handleLogout}
            className="flex items-center gap-1.5 text-gray-400 hover:text-red-400 border border-transparent hover:border-red-500/10"
          >
            <LogOut size={14} />
            <span className="hidden sm:inline">Sign Out</span>
          </Button>
        </div>
      </div>
      
      {/* Mobile nav indicator bar */}
      <div className="md:hidden flex justify-center gap-4 mt-3 pt-3 border-t border-white/5">
        <Link
          to="/"
          className={`flex items-center gap-1 text-xs font-medium py-1 px-3 rounded-full ${
            isActive("/") ? "bg-indigo-600/25 text-indigo-300" : "text-gray-400"
          }`}
        >
          <LayoutDashboard size={12} />
          Registrations
        </Link>
        <Link
          to="/events"
          className={`flex items-center gap-1 text-xs font-medium py-1 px-3 rounded-full ${
            isActive("/events") ? "bg-indigo-600/25 text-indigo-300" : "text-gray-400"
          }`}
        >
          <Calendar size={12} />
          Events Setup
        </Link>
      </div>
    </nav>
  );
}
