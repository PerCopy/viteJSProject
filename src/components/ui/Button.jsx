import React from "react";

export function Button({ 
  className = "", 
  variant = "primary", 
  size = "md", 
  children, 
  ...props 
}) {
  const baseStyles = "inline-flex items-center justify-center font-medium rounded-md transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-indigo-500/40 disabled:opacity-50 disabled:cursor-not-allowed glow-btn active:scale-95";
  
  const variants = {
    primary: "bg-indigo-600 hover:bg-indigo-500 text-white shadow-lg shadow-indigo-600/10 border border-indigo-500/20",
    secondary: "bg-gray-800 hover:bg-gray-700 text-gray-200 border border-gray-700/50",
    outline: "bg-transparent hover:bg-white/5 text-gray-300 border border-white/10",
    accent: "bg-purple-600 hover:bg-purple-500 text-white shadow-lg shadow-purple-600/10 border border-purple-500/20",
    ghost: "bg-transparent hover:bg-white/5 text-gray-400 hover:text-white",
    destructive: "bg-red-600/80 hover:bg-red-600 text-white border border-red-500/20"
  };
  
  const sizes = {
    sm: "px-3 py-1.5 text-xs",
    md: "px-4 py-2 text-sm",
    lg: "px-5 py-2.5 text-base"
  };
  
  return (
    <button 
      className={`${baseStyles} ${variants[variant]} ${sizes[size]} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
}
