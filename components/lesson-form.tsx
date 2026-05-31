"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export function LessonForm() {
  const router = useRouter();
  const [title, setTitle] = useState("");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  return (
    <form
      className="space-y-4"
      onSubmit={async (event) => {
        event.preventDefault();
        setError("");
        setIsSubmitting(true);

        const response = await fetch("/api/lessons", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ title }),
        });

        setIsSubmitting(false);

        if (!response.ok) {
          const payload = (await response.json()) as { error?: string };
          setError(payload.error ?? "Could not save lesson.");
          return;
        }

        const lesson = (await response.json()) as { id: string };

        router.push(`/lessons/${lesson.id}`);
        router.refresh();
      }}
    >
      <div className="space-y-2">
        <label className="text-sm font-medium text-slate-800" htmlFor="title">
          Lesson title
        </label>
        <input
          className="w-full rounded-2xl border border-slate-200 px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-slate-400"
          id="title"
          name="title"
          onChange={(event) => setTitle(event.target.value)}
          placeholder="e.g. Introduction to Neural Networks"
          required
          type="text"
          value={title}
        />
      </div>

      {error ? (
        <p className="rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </p>
      ) : null}

      <button
        className="inline-flex rounded-full bg-indigo-600 px-5 py-3 text-sm font-medium text-white shadow-[0_12px_25px_rgba(79,70,229,0.22)] transition hover:bg-indigo-500 disabled:opacity-60"
        disabled={isSubmitting}
        type="submit"
      >
        {isSubmitting ? "Saving..." : "Save lesson"}
      </button>
    </form>
  );
}
