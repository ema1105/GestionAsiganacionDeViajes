/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        // Superficies
        base: '#0D0D0D', // fondo principal
        surface: '#161616', // cards / inputs
        panel: '#0A0A0A', // contenedor principal / contenedores secundarios
        sidebar: '#111111',
        active: '#1F1B14', // item de nav activo
        // Acento premium
        gold: {
          DEFAULT: '#C9A96E',
          soft: '#D8C295',
          dim: '#8A7548',
        },
        // Texto
        ink: '#F5F0E8', // texto principal
        subtle: '#E8DFD0', // texto secundario
        muted: '#5C5247', // texto muted
        // Bordes
        line: '#2A2520',
        'line-soft': '#1E1A16',
        // Login columna izquierda
        cream: '#F5F0E8',
      },
      fontFamily: {
        sans: ['"DM Sans"', 'sans-serif'],
        serif: ['"Cormorant Garamond"', 'serif'],
      },
      boxShadow: {
        premium: '0 4px 24px -8px rgba(0, 0, 0, 0.6)',
        glow: '0 0 0 1px rgba(201, 169, 110, 0.15)',
      },
      transitionTimingFunction: {
        premium: 'cubic-bezier(0.4, 0, 0.2, 1)',
      },
      keyframes: {
        'fade-in': {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        'slide-up': {
          '0%': { opacity: '0', transform: 'translateY(8px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'toast-in': {
          '0%': { opacity: '0', transform: 'translateX(24px)' },
          '100%': { opacity: '1', transform: 'translateX(0)' },
        },
      },
      animation: {
        'fade-in': 'fade-in 0.2s ease',
        'slide-up': 'slide-up 0.25s ease',
        'toast-in': 'toast-in 0.25s ease',
      },
    },
  },
  plugins: [],
};
