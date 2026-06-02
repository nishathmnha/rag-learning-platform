import { answerLessonQuestionWithAgent } from "@/lib/ai/agents";
import { answerQuestionFromContext } from "@/lib/ai/chat-answer";
import { retrieveRelevantChunks } from "@/lib/rag/retrieve-chunks";

export async function chatWithLesson(
  lessonId: string,
  lessonTitle: string,
  question: string,
) {
  let answer: string | null = null;
  let relevantChunks: Awaited<ReturnType<typeof retrieveRelevantChunks>> = [];

  try {
    const agentResult = await answerLessonQuestionWithAgent({
      lessonId,
      lessonTitle,
      question,
    });

    answer = agentResult.answer.trim();
    relevantChunks = agentResult.relevantChunks;
  } catch {
    answer = null;
  }

  if (!answer || relevantChunks.length === 0) {
    relevantChunks = await retrieveRelevantChunks(lessonId, question, 6);

    if (relevantChunks.length === 0) {
      throw new Error("No chunks are available for this lesson yet.");
    }

    answer = await answerQuestionFromContext({
      lessonTitle,
      question,
      contextChunks: relevantChunks.map((chunk) => chunk.content),
    });
  }

  return {
    answer,
    relevantChunks,
  };
}
