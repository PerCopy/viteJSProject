import React from "react";

export const Input = React.forwardRef(({ className = "", label, error, ...props }, ref) => {
  return (
    <div className="w-full flex flex-col gap-1.5 text-left">
      {label && (
        <label className="text-xs font-semibold text-gray-300 uppercase tracking-wider">
          {label}
        </label>
      )}
      <input
        ref={ref}
        className={`w-full px-3.5 py-2 text-sm rounded-md glass-input ${
          error ? "border-red-500/60 focus:border-red-500/80 focus:ring-red-500/20" : ""
        } ${className}`}
        {...props}
      />
      {error && (
        <span className="text-xs text-red-400 mt-0.5">
          {error}
        </span>
      )}
    </div>
  );
});

Input.displayName = "Input";
