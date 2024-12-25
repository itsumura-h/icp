import { fileURLToPath, URL } from 'url';
import { defineConfig } from 'vite';
import EnvironmentPlugin from 'vite-plugin-environment';
import preact from '@preact/preset-vite';
import dotenv from 'dotenv';

dotenv.config({ path: '../../.env' });

export default defineConfig({
  build: {
    emptyOutDir: true,
  },
  optimizeDeps: {
    esbuildOptions: {
      define: {
        global: "globalThis",
      },
    },
  },
  server: {
    proxy: {
      "/api": {
        target: "http://127.0.0.1:4943",
        changeOrigin: true,
      },
    },
  },
  publicDir: "assets",
  plugins: [
    preact(),
    EnvironmentPlugin("all", { prefix: "CANISTER_" }),
    EnvironmentPlugin("all", { prefix: "DFX_" }),
  ],
  resolve: {
		alias:{
			"declarations": fileURLToPath(
				new URL("../declarations", import.meta.url)
			),
			"react": "preact/compat",
			"react-dom": "preact/compat",
		},
    dedupe: ['@dfinity/agent'],
  },
});
