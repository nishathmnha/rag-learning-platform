import { createEmbedding } from "@/lib/ai/embeddings";
import { queryLessonChunksFromLanceDb } from "@/lib/rag/lancedb";

type RetrievedChunk = {
  id: string;
  content: string;
  documentId: string;
  documentTitle: string;
  chunkIndex: number;
  score: number;
};

export async function retrieveRelevantChunks(
  lessonId: string,
  query: string,
  limit = 5,
) {
  const queryEmbedding = await createEmbedding(query);
  const rankedChunks = await queryLessonChunksFromLanceDb(
    lessonId,
    queryEmbedding,
    limit,
  );

  return rankedChunks satisfies RetrievedChunk[];
}
