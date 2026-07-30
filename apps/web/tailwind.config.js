/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "../../packages/ui/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        questBlue: "#2563EB",
        auroraPurple: "#7C3AED",
        midnightSlate: "#0F172A",
        deepGraphite: "#111827",
        gold: "#FBBF24",
        emerald: "#10B981",
        crimson: "#EF4444",
        skyBlue: "#38BDF8",
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
      animation: {
        'spring-up': 'springUp 300ms cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards',
      },
      keyframes: {
        springUp: {
          '0%': { transform: 'scale(0.95)', opacity: 0 },
          '100%': { transform: 'scale(1)', opacity: 1 },
        }
      }
    },
  },
  plugins: [],
}
