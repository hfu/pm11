import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    outDir: 'docs',
    rollupOptions: {
      output: {
        entryFileNames: 'index.js',
        chunkFileNames: 'index.js',
        assetFileNames: 'index.[ext]'
      }
    }
  }
});
