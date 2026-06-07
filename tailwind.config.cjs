/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        border: "rgba(255, 255, 255, 0.1)",
        input: "rgba(255, 255, 255, 0.05)",
        ring: "rgba(99, 102, 241, 0.5)",
        background: "#0b0f19",
        foreground: "#f3f4f6",
        primary: {
          DEFAULT: "#6366f1",
          hover: "#4f46e5",
          foreground: "#ffffff",
        },
        secondary: {
          DEFAULT: "#1f2937",
          hover: "#374151",
          foreground: "#f3f4f6",
        },
        card: {
          DEFAULT: "rgba(17, 24, 39, 0.7)",
          foreground: "#f3f4f6",
        },
        accent: {
          DEFAULT: "#8b5cf6",
          hover: "#7c3aed",
          foreground: "#ffffff",
        },
        muted: {
          DEFAULT: "#9ca3af",
          foreground: "#6b7280",
        }
      },
      borderRadius: {
        lg: "12px",
        md: "8px",
        sm: "4px",
      },
      keyframes: {
        fadeIn: {
          "0%": { opacity: 0, transform: "translateY(8px)" },
          "100%": { opacity: 1, transform: "translateY(0)" },
        },
        pulseGlow: {
          "0%, 100%": { opacity: 0.15, transform: "scale(1)" },
          "50%": { opacity: 0.35, transform: "scale(1.08)" },
        }
      },
      animation: {
        "fade-in": "fadeIn 0.4s ease-out forwards",
        "pulse-glow": "pulseGlow 10s infinite ease-in-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
}
