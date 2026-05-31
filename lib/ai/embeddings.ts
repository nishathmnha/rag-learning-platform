import { getOpenAIClient, openAIModels } from "@/lib/ai/openai";

export async function createEmbedding(input: string) {
  const client = getOpenAIClient();

  const response = await client.embeddings.create({
    model: openAIModels.embeddings,
    input,
    encoding_format: "float",
  });

  return response.data[0]?.embedding ?? [];
}
