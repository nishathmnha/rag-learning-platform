import { getOpenAIClient, openAIModels } from "@/lib/ai/openai";

type LessonGenerationInput = {
  lessonTitle: string;
  contextChunks: string[];
};

export async function generateLessonFromContext({
  lessonTitle,
  contextChunks,
}: LessonGenerationInput) {
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
              "You create structured, polished learning lessons. Use only the provided context. Do not invent facts. If the context is insufficient, explicitly say what is missing. Write in clean plain text with meaningful section headings, short paragraphs, and readable lists. Do not use markdown bold, asterisks around headings, or decorative separators.",
          },
        ],
      },
      {
        role: "user",
        content: [
          {
            type: "input_text",
            text: `Create a detailed lesson for "${lessonTitle}" using only this context:\n\n${context}\n\nRequirements:\n- Make the lesson substantial and useful, roughly 700 to 1200 words when the context supports it.\n- Use these section headings exactly, each on its own line:\nIntroduction:\nKey Concepts:\nExamples:\nSummary:\n- Under Key Concepts, explain multiple important points in depth.\n- Under Examples, include realistic examples grounded in the context.\n- Keep paragraphs short and readable, usually 2 to 4 sentences.\n- Prefer hyphen bullet points for grouped ideas unless sequence matters.\n- If you use numbered lists, keep them in ascending order and do not leave blank lines between list items.\n- Write in plain text only.\n- Do not use markdown bold like **text**.\n- Do not mention these instructions in the answer.`,
          },
        ],
      },
    ],
  });

  return response.output_text;
}
