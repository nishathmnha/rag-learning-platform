"use client";

import Link from "next/link";
import { useState } from "react";
import { useRouter } from "next/navigation";

type LessonItem = {
  id: string;
  title: string;
  createdAt: string;
  documentCount: number;
  assessmentCount: number;
  generatedLessonCount: number;
};

type LessonListProps = {
  lessons: LessonItem[];
};

export function LessonList({ lessons }: LessonListProps) {
  const router = useRouter();
  const [editingLessonId, setEditingLessonId] = useState<string | null>(null);
  const [draftTitle, setDraftTitle] = useState("");
  const [busyLessonId, setBusyLessonId] = useState<string | null>(null);
  const [error, setError] = useState("");

  async function handleDelete(lessonId: string) {
    setError("");
    setBusyLessonId(lessonId);

    const response = await fetch(`/api/lessons/${lessonId}`, {
      method: "DELETE",
    });

    setBusyLessonId(null);

    if (!response.ok) {
      const payload = (await response.json()) as { error?: string };
      setError(payload.error ?? "Could not delete lesson.");
      return;
    }

    router.refresh();
  }

  async function handleEditSave(lessonId: string) {
    setError("");
    setBusyLessonId(lessonId);

    const response = await fetch(`/api/lessons/${lessonId}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ title: draftTitle }),
    });

    setBusyLessonId(null);

    if (!response.ok) {
      const payload = (await response.json()) as { error?: string };
      setError(payload.error ?? "Could not update lesson.");
      return;
    }

    setEditingLessonId(null);
    setDraftTitle("");
    router.refresh();
  }

  return (
    <div className="mt-6 space-y-3">
      {error ? (
        <p className="rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-700">{error}</p>
      ) : null}

      {lessons.map((lesson) => {
        const isEditing = editingLessonId === lesson.id;
        const isBusy = busyLessonId === lesson.id;

        return (
          <div
            key={lesson.id}
            className="rounded-[1.5rem] border border-slate-200 bg-white/70 px-5 py-5 transition hover:border-indigo-200 hover:shadow-[0_12px_30px_rgba(99,102,241,0.10)]"
          >
            {isEditing ? (
              <div className="space-y-3">
                <input
                  className="w-full rounded-2xl border border-slate-200 px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-slate-400"
                  onChange={(event) => setDraftTitle(event.target.value)}
                  type="text"
                  value={draftTitle}
                />
                <div className="flex gap-3">
                  <button
                    className="inline-flex rounded-full bg-slate-900 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
                    disabled={isBusy}
                    onClick={() => handleEditSave(lesson.id)}
                    type="button"
                  >
                    {isBusy ? "Saving..." : "Save"}
                  </button>
                  <button
                    className="inline-flex rounded-full border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700"
                    disabled={isBusy}
                    onClick={() => {
                      setEditingLessonId(null);
                      setDraftTitle("");
                    }}
                    type="button"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            ) : (
              <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                <div className="space-y-3">
                  <div>
                    <p className="font-medium text-slate-900">{lesson.title}</p>
                    <p className="mt-1 text-sm text-slate-500">
                      Created {new Date(lesson.createdAt).toLocaleDateString()}
                    </p>
                  </div>

                  <div className="flex flex-wrap gap-2 text-xs">
                    <span className="rounded-full bg-slate-100 px-3 py-1 text-slate-700">
                      {lesson.documentCount} docs
                    </span>
                    <span className="rounded-full bg-slate-100 px-3 py-1 text-slate-700">
                      {lesson.generatedLessonCount} lessons
                    </span>
                    <span className="rounded-full bg-slate-100 px-3 py-1 text-slate-700">
                      {lesson.assessmentCount} quizzes
                    </span>
                  </div>

                  <Link
                    className="inline-flex text-sm font-medium text-indigo-600 transition hover:text-indigo-500"
                    href={`/lessons/${lesson.id}`}
                  >
                    Open workspace
                  </Link>
                </div>

                <div className="flex gap-3">
                  <button
                    className="inline-flex rounded-full border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50"
                    disabled={isBusy}
                    onClick={() => {
                      setError("");
                      setEditingLessonId(lesson.id);
                      setDraftTitle(lesson.title);
                    }}
                    type="button"
                  >
                    Edit
                  </button>
                  <button
                    className="inline-flex rounded-full border border-red-200 px-4 py-2 text-sm font-medium text-red-700 transition hover:bg-red-50 disabled:opacity-60"
                    disabled={isBusy}
                    onClick={() => handleDelete(lesson.id)}
                    type="button"
                  >
                    {isBusy ? "Removing..." : "Remove"}
                  </button>
                </div>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
