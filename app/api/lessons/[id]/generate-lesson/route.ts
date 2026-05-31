import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";

import { authOptions } from "@/auth";
import { prisma } from "@/lib/prisma";
import { generateLessonForLessonId } from "@/lib/rag/generate-lesson";

type Params = {
  params: Promise<{
    id: string;
  }>;
};

export async function POST(_request: Request, { params }: Params) {
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

  try {
    const result = await generateLessonForLessonId(lesson.id, lesson.title);

    return NextResponse.json({
      id: result.generatedLesson.id,
      content: result.generatedLesson.content,
      sourceCount: result.generatedLesson.sourceCount,
      chunks: result.relevantChunks.map((chunk) => ({
        id: chunk.id,
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
          error instanceof Error ? error.message : "Could not generate lesson.",
      },
      { status: 500 },
    );
  }
}
