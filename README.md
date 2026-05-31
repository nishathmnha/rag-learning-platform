# RAG Learning Platform

A simple learning-focused RAG project built with Next.js, Prisma, PostgreSQL, LanceDB, `next-auth`, and OpenAI.

## Current Phase

- Local username/password sign-up and sign-in
- Protected dashboard
- Create lesson page scaffold
- Separate `lib/ai` and `lib/rag` backend foundation
- Multi-file document ingestion for `pdf`, `docx`, and `txt`
- Shared retrieval for lesson generation, MCQ generation, and chat APIs

## Run Locally

1. Add your environment variables to `.env.local`

```env
DATABASE_URL="postgresql://USERNAME:PASSWORD@localhost:5432/rag_learning_platform?schema=public"
NEXTAUTH_SECRET="your-random-secret"
NEXTAUTH_URL="http://localhost:3000"
OPENAI_API_KEY="your-openai-api-key"
OPENAI_EMBEDDING_MODEL="text-embedding-3-small"
OPENAI_GENERATION_MODEL="gpt-4.1-mini"
LANCEDB_URI="./lancedb-data"
LANCEDB_TABLE="lesson_chunks"
```

2. Apply migrations

```bash
npx prisma migrate dev
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
- LanceDB
- Auth.js (`next-auth`)
- bcryptjs
- OpenAI Node SDK

## RAG Structure

- `lib/ai/*`
  - OpenAI client, embeddings, and lesson generation only
- `lib/rag/*`
  - chunking, LanceDB indexing/retrieval, and orchestration
- `app/api/lessons/[id]/documents`
  - ingest pasted text or uploaded `pdf/docx/txt` files and list lesson documents
- `app/api/lessons/[id]/generate-lesson`
  - retrieve chunks and generate a grounded lesson
- `app/api/lessons/[id]/generate-mcq`
  - retrieve chunks and generate MCQ assessments
- `app/api/lessons/[id]/chat`
  - retrieve chunks and answer lesson questions with sources
