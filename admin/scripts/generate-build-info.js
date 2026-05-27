/* eslint-disable */
/**
 * Pre-build: ghi `src/app/core/config/build-info.ts` với timestamp build hiện tại.
 * Mục đích: ép main bundle có nội dung khác sau mỗi build → Angular content-hash đổi
 *           → tên file `main-<hash>.js` mới → ép browser tải lại (cache bust mạnh).
 *
 * Chạy tự động qua `npm run build:prod` (xem package.json).
 */
const fs = require('fs');
const path = require('path');

const now = new Date();
const buildId = String(now.getTime());
const builtAt = now.toISOString();

const out = `// AUTO-GENERATED bởi scripts/generate-build-info.js — KHÔNG sửa tay.
// Mỗi lần chạy \`npm run build:prod\`, file này được ghi đè với timestamp mới
// để ép Angular sinh hash bundle mới (cache bust phía client).
export const BUILD_INFO = {
  buildId: '${buildId}',
  builtAt: '${builtAt}',
} as const;
`;

const target = path.join(__dirname, '..', 'src', 'app', 'core', 'config', 'build-info.ts');
fs.mkdirSync(path.dirname(target), { recursive: true });
fs.writeFileSync(target, out, 'utf8');

console.log(`[generate-build-info] ${target}`);
console.log(`  buildId = ${buildId}`);
console.log(`  builtAt = ${builtAt}`);
