"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { signIn } from "next-auth/react";

export function LoginForm() {
  const router = useRouter();
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  return (
    <form
      className="space-y-4"
      onSubmit={async (event) => {
        event.preventDefault();
        setError("");

        const formData = new FormData(event.currentTarget);
        const username = String(formData.get("username") ?? "").trim();
        const password = String(formData.get("password") ?? "");

        setIsSubmitting(true);

        const result = await signIn("credentials", {
          username,
          password,
          redirect: false,
          callbackUrl: "/dashboard",
        });

        setIsSubmitting(false);

        if (!result || result.error) {
          setError("Invalid username or password.");
          return;
        }

        router.push("/dashboard");
        router.refresh();
      }}
    >
      <div className="space-y-2">
        <label className="text-sm font-medium text-slate-800" htmlFor="username">
          Username
        </label>
        <input
          className="w-full rounded-2xl border border-slate-200 px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-slate-400"
          id="username"
          name="username"
          placeholder="Enter your username"
          required
          type="text"
        />
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium text-slate-800" htmlFor="password">
          Password
        </label>
        <input
          className="w-full rounded-2xl border border-slate-200 px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-slate-400"
          id="password"
          name="password"
          placeholder="Enter your password"
          required
          type="password"
        />
      </div>

      {error ? (
        <p className="rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-700">{error}</p>
      ) : null}

      <button
        className="inline-flex w-full items-center justify-center rounded-full bg-slate-900 px-5 py-3 text-sm font-medium text-white transition hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-60"
        disabled={isSubmitting}
        type="submit"
      >
        {isSubmitting ? "Signing in..." : "Sign in"}
      </button>
    </form>
  );
}
