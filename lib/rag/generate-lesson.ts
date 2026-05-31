import { prisma } from "@/lib/prisma";
import { generateLessonFromContext } from "@/lib/ai/lesson-generation";
import { retrieveRelevantChunks } from "@/lib/rag/retrieve-chunks";

export async function generateLessonForLessonId(
  lessonId: string,
  lessonTitle: string,
) {
  const relevantChunks = await retrieveRelevantChunks(lessonId, lessonTitle);

  if (relevantChunks.length === 0) {
    throw new Error("No chunks are available for this lesson yet.");
  }

  const content = await generateLessonFromContext({
    lessonTitle,
    contextChunks: relevantChunks.map((chunk) => chunk.content),
  });

  const generatedLesson = await prisma.generatedLesson.create({
    data: {
      lessonId,
      content,
      sourceCount: relevantChunks.length,
    },
  });

  return {
    generatedLesson,
    relevantChunks,
  };
}
