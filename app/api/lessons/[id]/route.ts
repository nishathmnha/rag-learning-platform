import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";

import { authOptions } from "@/auth";
import { prisma } from "@/lib/prisma";
import { deleteLessonVectorsFromLanceDb } from "@/lib/rag/lancedb";

type Params = {
  params: Promise<{
    id: string;
  }>;
};

export async function PATCH(request: Request, { params }: Params) {
  const session = await getServerSession(authOptions);

  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id } = await params;
  const body = (await request.json()) as { title?: string };
  const title = body.title?.trim() ?? "";

  if (title.length < 3) {
    return NextResponse.json(
      { error: "Title must be at least 3 characters long." },
      { status: 400 },
    );
  }

  const lesson = await prisma.lesson.findFirst({
    where: {
      id,
      userId: session.user.id,
    },
  });

  if (!lesson) {
    return NextResponse.json({ error: "Lesson not found." }, { status: 404 });
  }

  const updatedLesson = await prisma.lesson.update({
    where: {
      id,
    },
    data: {
      title,
    },
  });

  return NextResponse.json(updatedLesson);
}

export async function DELETE(_request: Request, { params }: Params) {
  const session = await getServerSession(authOptions);

  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id } = await params;

  const lesson = await prisma.lesson.findFirst({
    where: {
      id,
      userId: session.user.id,
    },
  });

  if (!lesson) {
    return NextResponse.json({ error: "Lesson not found." }, { status: 404 });
  }

  await prisma.lesson.delete({
    where: {
      id,
    },
  });

  try {
    await deleteLessonVectorsFromLanceDb(id);
  } catch (error) {
    if (process.env.NODE_ENV === "development") {
      console.warn("Could not delete lesson vectors from LanceDB.", error);
    }
  }

  return NextResponse.json({ success: true });
}
