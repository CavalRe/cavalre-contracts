import { defineConfig } from 'vite'
import { vitePluginTevm } from 'tevm/bundler/vite-plugin'

export default defineConfig({
  plugins: [vitePluginTevm()],
})
