import { tool } from "ai";
import { z } from "zod";

import { prisma } from "@/lib/prisma";
import { retrieveRelevantChunks } from "@/lib/rag/retrieve-chunks";

const lessonContextToolSchema = z.object({
  query: z
    .string()
    .trim()
    .min(1)
    .optional()
    .describe("The search query used to retrieve the most relevant lesson chunks."),
  limit: z
    .number()
    .int()
    .min(1)
    .max(12)
    .optional()
    .describe("How many relevant chunks to retrieve."),
});

const lessonSourcesToolSchema = z.object({
  includeChunkCounts: z
    .boolean()
    .optional()
    .describe("Whether to include chunk counts for each lesson source document."),
});

export type LessonContextToolResult = {
  query: string;
  sourceCount: number;
  chunks: Array<{
    id: string;
    content: string;
    documentId: string;
    documentTitle: string;
    chunkIndex: number;
    score: number;
  }>;
};

export type LessonSourcesToolResult = {
  sourceCount: number;
  documents: Array<{
    documentId: string;
    title: string;
    sourceType: string;
    fileName: string | null;
    chunkCount?: number;
  }>;
};

type LessonAgentToolOptions = {
  lessonId: string;
  defaultQuery: string;
  defaultLimit: number;
};

export function createLessonAgentTools({
  lessonId,
  defaultQuery,
  defaultLimit,
}: LessonAgentToolOptions) {
  return {
    get_lesson_context: tool({
      description:
        "Retrieve the most relevant lesson chunks for a lesson-specific query. Use this before writing lessons, quizzes, or grounded answers.",
      inputSchema: lessonContextToolSchema,
      execute: async ({
        query,
        limit,
      }): Promise<LessonContextToolResult> => {
        const nextQuery = query?.trim() || defaultQuery;
        const nextLimit = limit ?? defaultLimit;
        const chunks = await retrieveRelevantChunks(lessonId, nextQuery, nextLimit);

        return {
          query: nextQuery,
          sourceCount: chunks.length,
          chunks: chunks.map((chunk) => ({
            id: chunk.id,
            content: chunk.content,
            documentId: chunk.documentId,
            documentTitle: chunk.documentTitle,
            chunkIndex: chunk.chunkIndex,
            score: chunk.score,
          })),
        };
      },
    }),
    get_lesson_sources: tool({
      description:
        "List the documents available for a lesson so the agent can reason about source coverage and gaps before answering.",
      inputSchema: lessonSourcesToolSchema,
      execute: async ({
        includeChunkCounts = true,
      }): Promise<LessonSourcesToolResult> => {
        const documents = await prisma.lessonDocument.findMany({
          where: {
            lessonId,
          },
          include: {
            _count: {
              select: {
                chunks: true,
              },
            },
          },
          orderBy: {
            createdAt: "asc",
          },
        });

        return {
          sourceCount: documents.length,
          documents: documents.map((document) => ({
            documentId: document.id,
            title: document.title,
            sourceType: document.sourceType,
            fileName: document.fileName ?? null,
            chunkCount: includeChunkCounts ? document._count.chunks : undefined,
          })),
        };
      },
    }),
  } as const;
}
