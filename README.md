# RAG Learning Platform

A simple learning-focused RAG project built with Next.js, Prisma, PostgreSQL, and `next-auth`.

## Current Phase

- Local username/password sign-up and sign-in
- Protected dashboard
- Create lesson page scaffold

## Run Locally

1. Add your environment variables to `.env.local`

```env
DATABASE_URL="postgresql://USERNAME:PASSWORD@localhost:5432/rag_learning_platform?schema=public"
NEXTAUTH_SECRET="your-random-secret"
NEXTAUTH_URL="http://localhost:3000"
```

2. Apply migrations

```bash
npx prisma migrate dev --name credentials-auth
```

3. Start the app

```bash
npm run dev
```

4. Open `http://localhost:3000`

## Stack

- Next.js App Router
- Tailwind CSS
- Prisma
- PostgreSQL
- Auth.js (`next-auth`)
- bcryptjs
