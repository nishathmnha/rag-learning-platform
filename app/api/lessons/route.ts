import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";

import { authOptions } from "@/auth";
import { prisma } from "@/lib/prisma";

export async function POST(request: Request) {
  const session = await getServerSession(authOptions);

  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = (await request.json()) as { title?: string };
  const title = body.title?.trim() ?? "";

  if (title.length < 3) {
    return NextResponse.json(
      { error: "Title must be at least 3 characters long." },
      { status: 400 },
    );
  }

  const lesson = await prisma.lesson.create({
    data: {
      title,
      userId: session.user.id,
    },
  });

  return NextResponse.json(lesson, { status: 201 });
}
