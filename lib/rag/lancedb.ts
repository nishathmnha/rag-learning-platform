import "server-only";
import * as lancedb from "@lancedb/lancedb";

type LanceChunkRow = {
  id: string;
  lessonId: string;
  documentId: string;
  documentTitle: string;
  chunkIndex: number;
  content: string;
  vector: number[];
};

type UpsertLessonChunkInput = {
  id: string;
  values: number[];
  documentId: string;
  documentTitle: string;
  chunkIndex: number;
  content: string;
};

type LanceRetrievedChunk = {
  id: string;
  content: string;
  documentId: string;
  documentTitle: string;
  chunkIndex: number;
  score: number;
};

const lanceDbUri = process.env.LANCEDB_URI ?? "./lancedb-data";
const lessonChunkTableName = process.env.LANCEDB_TABLE ?? "lesson_chunks";

let lanceConnection: Awaited<ReturnType<typeof lancedb.connect>> | null = null;

function normalizeLanceError(error: unknown) {
  if (!(error instanceof Error)) {
    return new Error("LanceDB request failed.");
  }

  return error;
}

async function getLanceConnection() {
  lanceConnection ??= await lancedb.connect(lanceDbUri);

  return lanceConnection;
}

async function openLessonChunkTable() {
  try {
    const connection = await getLanceConnection();

    return await connection.openTable(lessonChunkTableName);
  } catch {
    return null;
  }
}

async function getOrCreateLessonChunkTable(seedRows?: LanceChunkRow[]) {
  const existingTable = await openLessonChunkTable();

  if (existingTable) {
    return existingTable;
  }

  const connection = await getLanceConnection();

  return connection.createTable(lessonChunkTableName, seedRows ?? [], {
    mode: "create",
    existOk: true,
  });
}

function escapeSqlLiteral(value: string) {
  return value.replace(/'/g, "''");
}

export async function upsertLessonChunksToLanceDb(
  lessonId: string,
  chunks: UpsertLessonChunkInput[],
) {
  try {
    const rows = chunks.map(
      (chunk) =>
        ({
          id: chunk.id,
          lessonId,
          documentId: chunk.documentId,
          documentTitle: chunk.documentTitle,
          chunkIndex: chunk.chunkIndex,
          content: chunk.content,
          vector: chunk.values,
        }) satisfies LanceChunkRow,
    );

    const table = await getOrCreateLessonChunkTable(rows);

    if (rows.length > 0) {
      await table.add(rows);
    }
  } catch (error) {
    throw normalizeLanceError(error);
  }
}

export async function queryLessonChunksFromLanceDb(
  lessonId: string,
  queryEmbedding: number[],
  limit: number,
) {
  try {
    const table = await openLessonChunkTable();

    if (!table) {
      return [] satisfies LanceRetrievedChunk[];
    }

    const rows = (await table
      .vectorSearch(queryEmbedding)
      .where(`lessonId = '${escapeSqlLiteral(lessonId)}'`)
      .limit(limit)
      .toArray()) as Array<
      LanceChunkRow & {
        _distance?: number;
      }
    >;

    return rows.map((row) => ({
      id: row.id,
      content: row.content,
      documentId: row.documentId,
      documentTitle: row.documentTitle,
      chunkIndex: row.chunkIndex,
      score: typeof row._distance === "number" ? 1 / (1 + row._distance) : 0,
    })) satisfies LanceRetrievedChunk[];
  } catch (error) {
    throw normalizeLanceError(error);
  }
}

export async function deleteLessonVectorsFromLanceDb(lessonId: string) {
  try {
    const table = await openLessonChunkTable();

    if (!table) {
      return;
    }

    await table.delete(`lessonId = '${escapeSqlLiteral(lessonId)}'`);
  } catch (error) {
    throw normalizeLanceError(error);
  }
}
