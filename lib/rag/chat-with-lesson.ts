import { answerQuestionFromContext } from "@/lib/ai/chat-answer";
import { retrieveRelevantChunks } from "@/lib/rag/retrieve-chunks";

export async function chatWithLesson(
  lessonId: string,
  lessonTitle: string,
  question: string,
) {
  const relevantChunks = await retrieveRelevantChunks(lessonId, question, 6);

  if (relevantChunks.length === 0) {
    throw new Error("No chunks are available for this lesson yet.");
  }

  const answer = await answerQuestionFromContext({
    lessonTitle,
    question,
    contextChunks: relevantChunks.map((chunk) => chunk.content),
  });

  return {
    answer,
    relevantChunks,
  };
}
