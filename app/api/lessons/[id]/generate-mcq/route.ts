import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";

import { authOptions } from "@/auth";
import { prisma } from "@/lib/prisma";
import { generateQuizForLessonId } from "@/lib/rag/generate-quiz";

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
  const body = (await request.json().catch(() => ({}))) as {
    questionCount?: number;
  };

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
    const result = await generateQuizForLessonId(
      lesson.id,
      lesson.title,
      body.questionCount ?? 5,
    );

    return NextResponse.json({
      id: result.assessment.id,
      title: result.assessment.title,
      questions: result.assessment.questions.map((question) => ({
        id: question.id,
        question: question.question,
        options: question.options,
        correctAnswer: question.correctAnswer,
        explanation: question.explanation,
      })),
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
          error instanceof Error ? error.message : "Could not generate quiz.",
      },
      { status: 500 },
    );
  }
}
