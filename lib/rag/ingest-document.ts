import { prisma } from "@/lib/prisma";
import { createEmbedding } from "@/lib/ai/embeddings";
import { chunkText } from "@/lib/rag/chunking";
import { ExtractedDocument } from "@/lib/rag/extract-document";
import { upsertLessonChunksToLanceDb } from "@/lib/rag/lancedb";

type IngestDocumentInput = {
  lessonId: string;
  title: string;
  rawText: string;
  sourceType?: ExtractedDocument["sourceType"];
  fileName?: string;
  mimeType?: string;
  size?: number;
};

export async function ingestTextDocument({
  lessonId,
  title,
  rawText,
  sourceType = "text",
  fileName,
  mimeType,
  size,
}: IngestDocumentInput) {
  const chunks = chunkText(rawText);

  if (chunks.length === 0) {
    throw new Error("Document text is empty after normalization.");
  }

  const embeddings = await Promise.all(chunks.map((chunk) => createEmbedding(chunk)));

  const { document, createdChunks } = await prisma.$transaction(async (transaction) => {
    const createdDocument = await transaction.lessonDocument.create({
      data: {
        lessonId,
        title,
        rawText,
        sourceType,
        fileName,
        mimeType,
        size,
      },
    });

    const nextChunks: Array<{
      id: string;
      content: string;
      chunkIndex: number;
      embedding: number[];
    }> = [];

    for (const [index, chunk] of chunks.entries()) {
      const createdChunk = await transaction.documentChunk.create({
        data: {
          lessonId,
          documentId: createdDocument.id,
          content: chunk,
          chunkIndex: index,
          embedding: embeddings[index],
        },
      });

      nextChunks.push({
        id: createdChunk.id,
        content: chunk,
        chunkIndex: index,
        embedding: embeddings[index],
      });
    }

    return {
      document: createdDocument,
      createdChunks: nextChunks,
    };
  });

  try {
    await upsertLessonChunksToLanceDb(
      lessonId,
      createdChunks.map((chunk) => ({
        id: chunk.id,
        values: chunk.embedding,
        documentId: document.id,
        documentTitle: title,
        chunkIndex: chunk.chunkIndex,
        content: chunk.content,
      })),
    );
  } catch (error) {
    await prisma.lessonDocument.delete({
      where: {
        id: document.id,
      },
    });

    throw new Error(
      error instanceof Error
        ? `Could not index document in LanceDB: ${error.message}`
        : "Could not index document in LanceDB.",
    );
  }

  return {
    documentId: document.id,
    chunkCount: chunks.length,
  };
}
