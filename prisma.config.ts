import { defineConfig, env } from "prisma/config";
import { existsSync } from "node:fs";

// Prisma CLI does not automatically mirror Next.js' `.env.local` behavior,
// so we load local env files explicitly for development commands.
if (existsSync(".env")) {
  process.loadEnvFile?.(".env");
}

if (existsSync(".env.local")) {
  process.loadEnvFile?.(".env.local");
}

export default defineConfig({
  schema: "prisma/schema.prisma",
  datasource: {
    url: env("DATABASE_URL"),
  },
});
