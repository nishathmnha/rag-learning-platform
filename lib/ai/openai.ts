import OpenAI from "openai";

const apiKey = process.env.OPENAI_API_KEY;

export function getOpenAIClient() {
  if (!apiKey) {
    throw new Error("OPENAI_API_KEY is not configured.");
  }

  return new OpenAI({ apiKey });
}

export const openAIModels = {
  embeddings: process.env.OPENAI_EMBEDDING_MODEL ?? "text-embedding-3-small",
  generation: process.env.OPENAI_GENERATION_MODEL ?? "gpt-4.1-mini",
} as const;
