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
    <main className="min-h-screen bg-slate-100 px-6 py-16">
      <div className="mx-auto max-w-2xl rounded-3xl bg-white p-8 shadow-sm">
        <div className="space-y-2">
          <p className="text-sm font-medium uppercase tracking-[0.2em] text-slate-500">
            Create Lesson
          </p>
          <h1 className="text-3xl font-semibold text-slate-900">
            Create a new lesson
          </h1>
          <p className="text-sm leading-6 text-slate-600">
            Give your lesson a clear title so you can attach documents to it in
            the next phase.
          </p>
        </div>

        <div className="mt-8">
          <LessonForm />
        </div>
      </div>
    </main>
  );
}
