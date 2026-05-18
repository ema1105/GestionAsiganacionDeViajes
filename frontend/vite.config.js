import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// El servidor de Vite corre en el puerto 5173, que ya está
// permitido en la configuración CORS del backend Spring Boot.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    open: true,
  },
});
