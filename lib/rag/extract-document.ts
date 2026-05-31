import { createRequire } from "node:module";

import mammoth from "mammoth";

const require = createRequire(import.meta.url);
const pdfParse = require("pdf-parse/lib/pdf-parse.js") as (
  dataBuffer: Buffer,
) => Promise<{ text: string }>;

export type ExtractedDocument = {
  title: string;
  rawText: string;
  sourceType: "pdf" | "docx" | "txt" | "text";
  fileName?: string;
  mimeType?: string;
  size?: number;
};

function getExtension(name: string) {
  const normalized = name.toLowerCase();

  if (normalized.endsWith(".pdf")) {
    return "pdf";
  }

  if (normalized.endsWith(".docx")) {
    return "docx";
  }

  if (normalized.endsWith(".txt")) {
    return "txt";
  }

  return "text";
}

export async function extractTextFromFile(file: File): Promise<ExtractedDocument> {
  const buffer = Buffer.from(await file.arrayBuffer());
  const extension = getExtension(file.name);

  if (extension === "pdf") {
    const parsed = await pdfParse(buffer);

    return {
      title: file.name.replace(/\.pdf$/i, ""),
      rawText: parsed.text,
      sourceType: "pdf",
      fileName: file.name,
      mimeType: file.type,
      size: file.size,
    };
  }

  if (extension === "docx") {
    const parsed = await mammoth.extractRawText({ buffer });

    return {
      title: file.name.replace(/\.docx$/i, ""),
      rawText: parsed.value,
      sourceType: "docx",
      fileName: file.name,
      mimeType: file.type,
      size: file.size,
    };
  }

  return {
    title: file.name.replace(/\.[^.]+$/i, ""),
    rawText: buffer.toString("utf8"),
    sourceType: "txt",
    fileName: file.name,
    mimeType: file.type || "text/plain",
    size: file.size,
  };
}
