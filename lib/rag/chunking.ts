type ChunkTextOptions = {
  chunkSize?: number;
  overlap?: number;
};

export function chunkText(text: string, options: ChunkTextOptions = {}) {
  const normalized = text.replace(/\r\n/g, "\n").trim();
  const chunkSize = options.chunkSize ?? 1200;
  const overlap = options.overlap ?? 200;

  if (!normalized) {
    return [];
  }

  const chunks: string[] = [];
  let start = 0;

  while (start < normalized.length) {
    const end = Math.min(start + chunkSize, normalized.length);
    const chunk = normalized.slice(start, end).trim();

    if (chunk) {
      chunks.push(chunk);
    }

    if (end >= normalized.length) {
      break;
    }

    start = Math.max(end - overlap, start + 1);
  }

  return chunks;
}
