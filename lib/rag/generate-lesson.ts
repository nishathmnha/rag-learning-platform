import { prisma } from "@/lib/prisma";
import { generateLessonWithAgent } from "@/lib/ai/agents";
import { generateLessonFromContext } from "@/lib/ai/lesson-generation";
import { retrieveRelevantChunks } from "@/lib/rag/retrieve-chunks";

export async function generateLessonForLessonId(
  lessonId: string,
  lessonTitle: string,
) {
  let content: string | null = null;
  let relevantChunks: Awaited<ReturnType<typeof retrieveRelevantChunks>> = [];

  try {
    const agentResult = await generateLessonWithAgent({
      lessonId,
      lessonTitle,
    });

    content = agentResult.content.trim();
    relevantChunks = agentResult.relevantChunks;
  } catch {
    content = null;
  }

  if (!content || relevantChunks.length === 0) {
    relevantChunks = await retrieveRelevantChunks(lessonId, lessonTitle);

    if (relevantChunks.length === 0) {
      throw new Error("No chunks are available for this lesson yet.");
    }

    content = await generateLessonFromContext({
      lessonTitle,
      contextChunks: relevantChunks.map((chunk) => chunk.content),
    });
  }

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
