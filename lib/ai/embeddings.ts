import { getOpenAIClient, openAIModels } from "@/lib/ai/openai";

const EMBEDDING_RETRY_DELAYS_MS = [250, 750, 1500] as const;

function sleep(delayMs: number) {
  return new Promise((resolve) => setTimeout(resolve, delayMs));
}

export async function createEmbedding(input: string) {
  const embeddings = await createEmbeddings([input]);

  return embeddings[0] ?? [];
}

export async function createEmbeddings(inputs: string[]) {
  if (inputs.length === 0) {
    return [];
  }

  const client = getOpenAIClient();

  let lastError: unknown = null;

  for (const [attemptIndex, delayMs] of EMBEDDING_RETRY_DELAYS_MS.entries()) {
    try {
      const response = await client.embeddings.create({
        model: openAIModels.embeddings,
        input: inputs,
        encoding_format: "float",
      });

      return response.data.map((item) => item.embedding ?? []);
    } catch (error) {
      lastError = error;

      if (attemptIndex < EMBEDDING_RETRY_DELAYS_MS.length - 1) {
        await sleep(delayMs);
      }
    }
  }

  throw lastError instanceof Error
    ? new Error(`Could not create embeddings. ${lastError.message}`)
    : new Error("Could not create embeddings.");
}
