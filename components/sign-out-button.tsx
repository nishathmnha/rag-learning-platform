"use client";

import { signOut } from "next-auth/react";

export function SignOutButton() {
  return (
    <button
      className="inline-flex rounded-full border border-slate-200 px-5 py-3 text-sm font-medium text-slate-700 transition hover:border-slate-300 hover:bg-slate-50"
      onClick={() => signOut({ callbackUrl: "/login" })}
      type="button"
    >
      Sign out
    </button>
  );
}
