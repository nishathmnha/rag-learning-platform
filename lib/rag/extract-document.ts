import { createRequire } from "node:module";

import mammoth from "mammoth";

const require = createRequire(import.meta.url);
const pdfParse = require("pdf-parse/lib/pdf-parse.js") as (
  dataBuffer: Buffer,
  options?: { version?: string },
) => Promise<{ text: string }>;
const pdfParseFallbackVersions = [
  undefined,
  "v1.10.100",
  "v1.10.88",
  "v1.9.426",
  "v2.0.550",
] as const;

export type ExtractedDocument = {
  title: string;
  rawText: string;
  sourceType: "pdf" | "docx" | "txt" | "text";
  fileName?: string;
  mimeType?: string;
  size?: number;
};

function hasZipSignature(buffer: Buffer) {
  return buffer.length >= 4 && buffer[0] === 0x50 && buffer[1] === 0x4b;
}

function normalizeExtractedText(text: string) {
  return text
    .replace(/\u0000/g, " ")
    .replace(/\r\n/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function isProbablyBinaryText(buffer: Buffer) {
  if (buffer.length === 0) {
    return false;
  }

  let nullByteCount = 0;

  for (const value of buffer) {
    if (value === 0) {
      nullByteCount += 1;
    }
  }

  return nullByteCount / buffer.length > 0.05;
}

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

  if (buffer.length === 0) {
    throw new Error("The uploaded file is empty.");
  }

  if (extension === "pdf") {
    try {
      let parsedText = "";
      let lastError: unknown = null;

      for (const version of pdfParseFallbackVersions) {
        try {
          const parsed = version
            ? await pdfParse(buffer, { version })
            : await pdfParse(buffer);
          parsedText = normalizeExtractedText(parsed.text);

          if (parsedText) {
            break;
          }
        } catch (error) {
          lastError = error;
        }
      }

      if (!parsedText) {
        if (lastError instanceof Error) {
          throw lastError;
        }

        throw new Error("No readable text was found in the PDF.");
      }

      return {
        title: file.name.replace(/\.pdf$/i, ""),
        rawText: parsedText,
        sourceType: "pdf",
        fileName: file.name,
        mimeType: file.type,
        size: file.size,
      };
    } catch (error) {
      throw new Error(
        error instanceof Error
          ? `Could not read PDF content. ${error.message}`
          : "Could not read PDF content.",
      );
    }
  }

  if (extension === "docx") {
    if (!hasZipSignature(buffer)) {
      throw new Error(
        "This Word document is not a valid DOCX file. Please re-save it as DOCX and try again.",
      );
    }

    try {
      const parsed = await mammoth.extractRawText({ buffer });
      const rawText = normalizeExtractedText(parsed.value);

      if (!rawText) {
        throw new Error("No readable text was found in the DOCX file.");
      }

      return {
        title: file.name.replace(/\.docx$/i, ""),
        rawText,
        sourceType: "docx",
        fileName: file.name,
        mimeType: file.type,
        size: file.size,
      };
    } catch (error) {
      throw new Error(
        error instanceof Error
          ? `Could not read DOCX content. ${error.message}`
          : "Could not read DOCX content.",
      );
    }
  }

  if (isProbablyBinaryText(buffer)) {
    throw new Error(
      "This text file appears to be binary or encoded in an unsupported format. Please upload a UTF-8 TXT file.",
    );
  }

  const rawText = normalizeExtractedText(buffer.toString("utf8"));

  if (!rawText) {
    throw new Error("No readable text was found in the TXT file.");
  }

  return {
    title: file.name.replace(/\.[^.]+$/i, ""),
    rawText,
    sourceType: "txt",
    fileName: file.name,
    mimeType: file.type || "text/plain",
    size: file.size,
  };
}
