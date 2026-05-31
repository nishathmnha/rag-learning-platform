import Link from "next/link";
import { redirect } from "next/navigation";
import { getServerSession } from "next-auth";

import { authOptions } from "@/auth";
import { LoginForm } from "@/components/login-form";

export default async function LoginPage() {
  const session = await getServerSession(authOptions);

  if (session) {
    redirect("/dashboard");
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-50 px-6 py-16">
      <section className="w-full max-w-sm rounded-3xl border border-slate-200 bg-white p-8 shadow-sm">
        <div className="space-y-2 text-center">
          <p className="text-xs font-medium uppercase tracking-[0.25em] text-slate-500">
            RAG Learning Platform
          </p>
          <h1 className="text-3xl font-semibold text-slate-900">Sign in</h1>
          <p className="text-sm leading-6 text-slate-600">
            Use your username and password to continue.
          </p>
        </div>

        <div className="mt-8">
          <LoginForm />
        </div>

        <p className="mt-6 text-center text-sm text-slate-500">
          New here?{" "}
          <Link className="font-medium text-slate-900 underline" href="/signup">
            Create an account
          </Link>
        </p>
      </section>
    </main>
  );
}
