import Link from "next/link";
import { redirect } from "next/navigation";
import { getServerSession } from "next-auth";

import { authOptions } from "@/auth";
import { prisma } from "@/lib/prisma";
import { SignOutButton } from "@/components/sign-out-button";

export default async function DashboardPage() {
  const session = await getServerSession(authOptions);

  if (!session?.user) {
    redirect("/login");
  }

  const lessons = await prisma.lesson.findMany({
    where: {
      userId: session.user.id,
    },
    orderBy: {
      createdAt: "desc",
    },
  });

  return (
    <main className="min-h-screen bg-slate-100 px-6 py-16">
      <div className="mx-auto max-w-4xl space-y-8">
        <header className="flex flex-col gap-4 rounded-3xl bg-white p-8 shadow-sm sm:flex-row sm:items-center sm:justify-between">
          <div className="space-y-2">
            <p className="text-sm font-medium uppercase tracking-[0.2em] text-slate-500">
              Dashboard
            </p>
            <h1 className="text-3xl font-semibold text-slate-900">
              Welcome, {session.user.username ?? session.user.name ?? "Learner"}
            </h1>
            <p className="text-sm text-slate-600">
              This is your protected workspace for creating and managing lessons.
            </p>
          </div>
          <SignOutButton />
        </header>

        <section className="grid gap-6 md:grid-cols-2">
          <article className="rounded-3xl bg-white p-6 shadow-sm">
            <h2 className="text-xl font-semibold text-slate-900">Authentication</h2>
            <p className="mt-4 text-sm leading-6 text-slate-600">
              Sign up, sign in, and route protection are all working with local
              username and password authentication.
            </p>
          </article>

          <article className="rounded-3xl bg-white p-6 shadow-sm">
            <h2 className="text-xl font-semibold text-slate-900">Create lesson</h2>
            <p className="mt-4 text-sm leading-6 text-slate-600">
              Start a new lesson by adding a title. This is the next step in the
              learning workflow.
            </p>
            <Link
              className="mt-6 inline-flex rounded-full bg-slate-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-slate-700"
              href="/lessons/new"
            >
              New lesson
            </Link>
          </article>
        </section>

        <section className="rounded-3xl bg-white p-6 shadow-sm">
          <div className="flex items-center justify-between gap-4">
            <div>
              <h2 className="text-xl font-semibold text-slate-900">Your lessons</h2>
              <p className="mt-1 text-sm text-slate-600">
                Lesson titles you have already created.
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
            <ul className="mt-6 space-y-3">
              {lessons.map((lesson) => (
                <li
                  key={lesson.id}
                  className="rounded-2xl border border-slate-200 px-4 py-4"
                >
                  <p className="font-medium text-slate-900">{lesson.title}</p>
                  <p className="mt-1 text-sm text-slate-500">
                    Created {lesson.createdAt.toLocaleDateString()}
                  </p>
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>
    </main>
  );
}
