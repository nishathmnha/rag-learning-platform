import { prisma } from "@/lib/prisma";
import { generateQuizFromContext } from "@/lib/ai/quiz-generation";
import { retrieveRelevantChunks } from "@/lib/rag/retrieve-chunks";

export async function generateQuizForLessonId(
  lessonId: string,
  lessonTitle: string,
  questionCount = 5,
) {
  const relevantChunks = await retrieveRelevantChunks(lessonId, lessonTitle, 8);

  if (relevantChunks.length === 0) {
    throw new Error("No chunks are available for this lesson yet.");
  }

  const questions = await generateQuizFromContext({
    lessonTitle,
    contextChunks: relevantChunks.map((chunk) => chunk.content),
    questionCount,
  });

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
