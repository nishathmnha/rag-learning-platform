import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";

import { authOptions } from "@/auth";
import { prisma } from "@/lib/prisma";
import { chatWithLesson } from "@/lib/rag/chat-with-lesson";

type Params = {
  params: Promise<{
    id: string;
  }>;
};

export async function POST(request: Request, { params }: Params) {
  const session = await getServerSession(authOptions);

  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id } = await params;
  const body = (await request.json()) as { question?: string };
  const question = body.question?.trim() ?? "";

  if (question.length < 3) {
    return NextResponse.json(
      { error: "Question must be at least 3 characters long." },
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

  try {
    const result = await chatWithLesson(lesson.id, lesson.title, question);

    return NextResponse.json({
      answer: result.answer,
      sources: result.relevantChunks.map((chunk) => ({
        documentId: chunk.documentId,
        documentTitle: chunk.documentTitle,
        chunkIndex: chunk.chunkIndex,
        score: chunk.score,
      })),
    });
  } catch (error) {
    return NextResponse.json(
      {
        error:
          error instanceof Error ? error.message : "Could not answer question.",
      },
      { status: 500 },
    );
  }
}
