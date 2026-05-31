import { redirect } from "next/navigation";
import { getServerSession } from "next-auth";

import { authOptions } from "@/auth";
import { LessonForm } from "@/components/lesson-form";

export default async function NewLessonPage() {
  const session = await getServerSession(authOptions);

  if (!session?.user) {
    redirect("/login");
  }

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top_left,_rgba(99,102,241,0.10),_transparent_35%),linear-gradient(180deg,#f8fafc_0%,#eef2ff_100%)] px-6 py-16">
      <div className="mx-auto max-w-3xl rounded-[2rem] border border-white/80 bg-white/90 p-8 shadow-[0_24px_60px_rgba(15,23,42,0.08)]">
        <div className="space-y-2">
          <p className="text-sm font-medium uppercase tracking-[0.3em] text-indigo-500">
            Create Lesson
          </p>
          <h1 className="text-4xl font-semibold tracking-tight text-slate-950">
            Create a new lesson
          </h1>
          <p className="text-sm leading-6 text-slate-600">
            Start with a lesson title, then move into the workspace to upload
            multiple source files, generate grounded lessons, build quizzes, and
            chat with the material.
          </p>
        </div>

        <div className="mt-8 grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
          <LessonForm />

          <aside className="rounded-[1.75rem] bg-slate-950 p-6 text-white">
            <h2 className="text-xl font-semibold">What happens next</h2>
            <ol className="mt-4 space-y-3 text-sm text-slate-200">
              <li>1. Create the lesson workspace</li>
              <li>2. Attach PDF, DOCX, or TXT documents</li>
              <li>3. Generate lesson notes from retrieved chunks</li>
              <li>4. Build MCQs and chat with the lesson corpus</li>
            </ol>
          </aside>
        </div>
      </div>
    </main>
  );
}
