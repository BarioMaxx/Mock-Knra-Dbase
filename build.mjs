import { rm, mkdir, writeFile } from 'node:fs/promises';
import { build } from 'esbuild';

await rm('dist', { recursive: true, force: true });
await mkdir('dist/assets', { recursive: true });

await build({
  entryPoints: ['src/main.jsx'],
  bundle: true,
  minify: true,
  sourcemap: false,
  format: 'esm',
  splitting: false,
  loader: {
    '.jsx': 'jsx',
    '.js': 'jsx'
  },
  entryNames: 'index',
  assetNames: 'assets/[name]',
  outdir: 'dist/assets'
});

await writeFile(
  'dist/index.html',
  `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>KNRA Licensing Records</title>
    <link rel="stylesheet" href="/assets/index.css" />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/assets/index.js"></script>
  </body>
</html>
`
);
