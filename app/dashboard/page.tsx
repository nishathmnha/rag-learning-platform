import Link from "next/link";
import { redirect } from "next/navigation";
import { getServerSession } from "next-auth";

import { authOptions } from "@/auth";
import { LessonList } from "@/components/lesson-list";
import { prisma } from "@/lib/prisma";
import { SignOutButton } from "@/components/sign-out-button";

function TechBadge({
  label,
  description,
  icon,
}: {
  label: string;
  description: string;
  icon: React.ReactNode;
}) {
  return (
    <article className="rounded-[1.5rem] border border-slate-200 bg-slate-50/80 p-4">
      <div className="flex items-center gap-3">
        <div className="rounded-2xl bg-white p-3 shadow-sm">{icon}</div>
        <div>
          <p className="text-sm font-semibold text-slate-950">{label}</p>
          <p className="text-xs text-slate-500">{description}</p>
        </div>
      </div>
    </article>
  );
}

export default async function DashboardPage() {
  const session = await getServerSession(authOptions);

  if (!session?.user) {
    redirect("/login");
  }

  const lessons = await prisma.lesson.findMany({
    where: {
      userId: session.user.id,
    },
    include: {
      _count: {
        select: {
          documents: true,
          assessments: true,
          generatedLessons: true,
          chunks: true,
        },
      },
    },
    orderBy: {
      createdAt: "desc",
    },
  });

  const [documentCount, assessmentCount, generatedLessonCount, chunkCount] =
    await Promise.all([
      prisma.lessonDocument.count({
        where: {
          lesson: {
            userId: session.user.id,
          },
        },
      }),
      prisma.lessonAssessment.count({
        where: {
          lesson: {
            userId: session.user.id,
          },
        },
      }),
      prisma.generatedLesson.count({
        where: {
          lesson: {
            userId: session.user.id,
          },
        },
      }),
      prisma.documentChunk.count({
        where: {
          lesson: {
            userId: session.user.id,
          },
        },
      }),
    ]);

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top_left,_rgba(99,102,241,0.12),_transparent_35%),linear-gradient(180deg,#f8fafc_0%,#eef2ff_100%)] px-6 py-12">
      <div className="mx-auto max-w-6xl space-y-8">
        <section className="rounded-[2rem] border border-white/80 bg-white/90 p-6 shadow-[0_18px_45px_rgba(15,23,42,0.05)]">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p className="text-sm font-medium uppercase tracking-[0.3em] text-indigo-500">
                Platform Stack
              </p>
              <h2 className="mt-2 text-2xl font-semibold tracking-tight text-slate-950">
                Powered by the core technologies behind this workspace
              </h2>
            </div>
            <p className="max-w-xl text-sm leading-6 text-slate-600">
              This build is running on Next.js with PostgreSQL, LanceDB, Prisma,
              and OpenAI for embeddings and generation.
            </p>
          </div>

          <div className="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-5">
            <TechBadge
              label="Next.js"
              description="App Router UI + API routes"
              icon={
                <svg aria-hidden="true" className="h-5 w-5 text-slate-950" viewBox="0 0 24 24" fill="none">
                  <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="1.5" />
                  <path
                    d="M9 8v8M9 8l6 8M15 16V8"
                    stroke="currentColor"
                    strokeWidth="1.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              }
            />
            <TechBadge
              label="PostgreSQL"
              description="Lessons, docs, and metadata"
              icon={
                <svg aria-hidden="true" className="h-5 w-5 text-slate-950" viewBox="0 0 24 24" fill="none">
                  <ellipse cx="12" cy="7" rx="6" ry="3.5" stroke="currentColor" strokeWidth="1.5" />
                  <path d="M6 7v6.5c0 1.9 2.7 3.5 6 3.5s6-1.6 6-3.5V7" stroke="currentColor" strokeWidth="1.5" />
                  <path d="M6 10.5c0 1.9 2.7 3.5 6 3.5s6-1.6 6-3.5" stroke="currentColor" strokeWidth="1.5" />
                </svg>
              }
            />
            <TechBadge
              label="Prisma"
              description="Type-safe data layer"
              icon={
                <svg aria-hidden="true" className="h-5 w-5 text-slate-950" viewBox="0 0 24 24" fill="none">
                  <path
                    d="M9 4h6l4 7-7 9L5 9l4-5Z"
                    stroke="currentColor"
                    strokeWidth="1.5"
                    strokeLinejoin="round"
                  />
                  <path d="M9 4l3 16 7-9" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
                </svg>
              }
            />
            <TechBadge
              label="OpenAI"
              description="Embeddings + generation"
              icon={
                <svg aria-hidden="true" className="h-5 w-5 text-slate-950" viewBox="0 0 24 24" fill="none">
                  <path
                    d="M12 4.5 6.5 7.7v6.6l5.5 3.2 5.5-3.2V7.7 4.5"
                    stroke="currentColor"
                    strokeWidth="1.5"
                    strokeLinejoin="round"
                  />
                  <path
                    d="M9 6.3 15 9.7v6.6M15 6.3 9 9.7v6.6"
                    stroke="currentColor"
                    strokeWidth="1.5"
                    strokeLinejoin="round"
                  />
                </svg>
              }
            />
            <TechBadge
              label="LanceDB"
              description="Embedded local vector store"
              icon={
                <svg aria-hidden="true" className="h-5 w-5 text-slate-950" viewBox="0 0 24 24" fill="none">
                  <path d="M5 8h14M5 12h14M5 16h8" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
                  <circle cx="17.5" cy="16.5" r="2.5" stroke="currentColor" strokeWidth="1.5" />
                </svg>
              }
            />
          </div>
        </section>

        <header className="flex flex-col gap-6 rounded-[2rem] border border-white/70 bg-white/90 p-8 shadow-[0_24px_60px_rgba(15,23,42,0.08)] backdrop-blur sm:flex-row sm:items-center sm:justify-between">
          <div className="space-y-3">
            <p className="text-sm font-medium uppercase tracking-[0.3em] text-indigo-500">
              Dashboard
            </p>
            <h1 className="text-4xl font-semibold tracking-tight text-slate-950">
              Welcome, {session.user.username ?? session.user.name ?? "Learner"}
            </h1>
            <p className="max-w-2xl text-sm leading-6 text-slate-600">
              Build lesson workspaces, attach multiple source documents, generate
              grounded lessons and quizzes, and chat with your course material.
            </p>
            <p className="text-xs font-medium uppercase tracking-[0.2em] text-slate-500">
              Crafted by Ahamed Nishath
            </p>
          </div>
          <SignOutButton />
        </header>

        <section className="grid gap-4 md:grid-cols-4">
          {[
            {
              label: "Total lessons",
              value: lessons.length,
              hint: "Lesson workspaces",
            },
            {
              label: "Documents",
              value: documentCount,
              hint: "PDF, DOCX, TXT",
            },
            {
              label: "Chunks",
              value: chunkCount,
              hint: "Retrieval-ready",
            },
            {
              label: "Assessments",
              value: assessmentCount,
              hint: `${generatedLessonCount} generated lessons`,
            },
          ].map((stat, index) => (
            <article
              key={stat.label}
              className="rounded-[1.75rem] border border-white/80 bg-white/90 p-5 shadow-[0_18px_45px_rgba(15,23,42,0.05)]"
            >
              <p className="text-sm font-medium text-slate-500">{stat.label}</p>
              <div className="mt-4 flex items-end justify-between gap-3">
                <p className="text-4xl font-semibold tracking-tight text-slate-950">
                  {stat.value}
                </p>
                <span className="rounded-full bg-indigo-50 px-3 py-1 text-xs font-medium text-indigo-600">
                  0{index + 1}
                </span>
              </div>
              <p className="mt-3 text-sm text-slate-500">{stat.hint}</p>
            </article>
          ))}
        </section>

        <section className="grid gap-6 xl:grid-cols-[1.7fr_1fr]">
          <section className="rounded-[2rem] border border-white/80 bg-white/90 p-6 shadow-[0_18px_45px_rgba(15,23,42,0.05)]">
            <div className="flex items-center justify-between gap-4">
              <div>
                <h2 className="text-xl font-semibold text-slate-950">Your lessons</h2>
                <p className="mt-1 text-sm text-slate-600">
                  Jump into any lesson to manage source files, generated notes,
                  assessments, and chat.
                </p>
              </div>
              <span className="rounded-full bg-slate-100 px-3 py-1 text-sm text-slate-700">
                {lessons.length}
              </span>
            </div>

            {lessons.length === 0 ? (
              <p className="mt-6 rounded-2xl border border-dashed border-slate-200 px-4 py-6 text-sm text-slate-500">
                No lessons yet. Create your first lesson to begin.
              </p>
            ) : (
              <LessonList
                lessons={lessons.map((lesson) => ({
                  id: lesson.id,
                  title: lesson.title,
                  createdAt: lesson.createdAt.toISOString(),
                  documentCount: lesson._count.documents,
                  assessmentCount: lesson._count.assessments,
                  generatedLessonCount: lesson._count.generatedLessons,
                }))}
              />
            )}
          </section>

          <aside className="space-y-6">
            <section className="rounded-[2rem] border border-white/80 bg-white/90 p-6 shadow-[0_18px_45px_rgba(15,23,42,0.05)]">
              <h2 className="text-xl font-semibold text-slate-950">Create lesson</h2>
              <p className="mt-3 text-sm leading-6 text-slate-600">
                Start with a title, then attach multiple PDF, DOCX, or TXT files
                to build a lesson-specific knowledge base.
              </p>
              <Link
                className="mt-6 inline-flex rounded-full bg-slate-950 px-5 py-3 text-sm font-medium text-white transition hover:bg-slate-800"
                href="/lessons/new"
              >
                New lesson
              </Link>
            </section>

            <section className="rounded-[2rem] border border-white/80 bg-slate-950 p-6 text-white shadow-[0_18px_45px_rgba(15,23,42,0.18)]">
              <h2 className="text-xl font-semibold">RAG workflow</h2>
              <ol className="mt-4 space-y-3 text-sm text-slate-200">
                <li>1. Create a lesson workspace</li>
                <li>2. Upload multiple source documents</li>
                <li>3. Chunk and embed lesson content</li>
                <li>4. Generate lessons, quizzes, and chat answers</li>
              </ol>
            </section>
          </aside>
        </section>

      </div>
    </main>
  );
}
