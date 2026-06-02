import { prisma } from "@/lib/prisma";
import { generateQuizWithAgent } from "@/lib/ai/agents";
import { generateQuizFromContext } from "@/lib/ai/quiz-generation";
import { retrieveRelevantChunks } from "@/lib/rag/retrieve-chunks";

export async function generateQuizForLessonId(
  lessonId: string,
  lessonTitle: string,
  questionCount = 5,
) {
  let questions: Awaited<ReturnType<typeof generateQuizFromContext>> | null = null;
  let relevantChunks: Awaited<ReturnType<typeof retrieveRelevantChunks>> = [];

  try {
    const agentResult = await generateQuizWithAgent({
      lessonId,
      lessonTitle,
      questionCount,
    });

    questions = agentResult.questions;
    relevantChunks = agentResult.relevantChunks;
  } catch {
    questions = null;
  }

  if (!questions || relevantChunks.length === 0) {
    relevantChunks = await retrieveRelevantChunks(lessonId, lessonTitle, 8);

    if (relevantChunks.length === 0) {
      throw new Error("No chunks are available for this lesson yet.");
    }

    questions = await generateQuizFromContext({
      lessonTitle,
      contextChunks: relevantChunks.map((chunk) => chunk.content),
      questionCount,
    });
  }

  const assessment = await prisma.lessonAssessment.create({
    data: {
      lessonId,
      title: `${lessonTitle} Quiz`,
      questions: {
        create: questions.map((question, index) => ({
          question: question.question,
          options: question.options,
          correctAnswer: question.correctAnswer,
          explanation: question.explanation,
          questionIndex: index,
        })),
      },
    },
    include: {
      questions: {
        orderBy: {
          questionIndex: "asc",
        },
      },
    },
  });

  return {
    assessment,
    relevantChunks,
  };
}
