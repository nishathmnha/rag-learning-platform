import { getOpenAIClient, openAIModels } from "@/lib/ai/openai";

type ChatAnswerInput = {
  lessonTitle: string;
  question: string;
  contextChunks: string[];
};

export async function answerQuestionFromContext({
  lessonTitle,
  question,
  contextChunks,
}: ChatAnswerInput) {
  const client = getOpenAIClient();

  const context = contextChunks
    .map((chunk, index) => `Source ${index + 1}:\n${chunk}`)
    .join("\n\n");

  const response = await client.responses.create({
    model: openAIModels.generation,
    input: [
      {
        role: "system",
        content: [
          {
            type: "input_text",
            text:
              "You answer questions using only the provided lesson context. If the answer is not in the sources, clearly say that the context does not contain enough information.",
          },
        ],
      },
      {
        role: "user",
        content: [
          {
            type: "input_text",
            text: `Lesson: "${lessonTitle}"\nQuestion: ${question}\n\nUse only these sources:\n\n${context}`,
          },
        ],
      },
    ],
  });

  return response.output_text;
}
