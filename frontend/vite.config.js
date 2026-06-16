import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// During development the Flask API runs on :5000; proxy /api and /health to it.
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': 'http://localhost:5000',
      '/health': 'http://localhost:5000',
    },
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
})
