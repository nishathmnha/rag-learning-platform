import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";

import { authOptions } from "@/auth";
import { prisma } from "@/lib/prisma";
import { extractTextFromFile } from "@/lib/rag/extract-document";
import { ingestTextDocument } from "@/lib/rag/ingest-document";

type Params = {
  params: Promise<{
    id: string;
  }>;
};

export async function GET(_request: Request, { params }: Params) {
  const session = await getServerSession(authOptions);

  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id } = await params;

  const lesson = await prisma.lesson.findFirst({
    where: {
      id,
      userId: session.user.id,
    },
    include: {
      documents: {
        orderBy: {
          createdAt: "desc",
        },
      },
    },
  });

  if (!lesson) {
    return NextResponse.json({ error: "Lesson not found." }, { status: 404 });
  }

  return NextResponse.json(lesson.documents);
}

export async function POST(request: Request, { params }: Params) {
  const session = await getServerSession(authOptions);

  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id } = await params;

  const lesson = await prisma.lesson.findFirst({
    where: {
      id,
      userId: session.user.id,
    },
  });

  if (!lesson) {
    return NextResponse.json({ error: "Lesson not found." }, { status: 404 });
  }

  try {
    const contentType = request.headers.get("content-type") ?? "";

    if (contentType.includes("multipart/form-data")) {
      const formData = await request.formData();
      const files = formData
        .getAll("files")
        .filter((value): value is File => value instanceof File);

      if (files.length === 0) {
        return NextResponse.json(
          { error: "At least one file is required." },
          { status: 400 },
        );
      }

      const results = [];

      for (const file of files) {
        const extracted = await extractTextFromFile(file);

        if (extracted.rawText.trim().length < 20) {
          continue;
        }

        const result = await ingestTextDocument({
          lessonId: lesson.id,
          title: extracted.title,
          rawText: extracted.rawText,
          sourceType: extracted.sourceType,
          fileName: extracted.fileName,
          mimeType: extracted.mimeType,
          size: extracted.size,
        });

        results.push({
          ...result,
          title: extracted.title,
          sourceType: extracted.sourceType,
        });
      }

      if (results.length === 0) {
        return NextResponse.json(
          { error: "No readable document text was extracted from the uploaded files." },
          { status: 400 },
        );
      }

      return NextResponse.json({ documents: results }, { status: 201 });
    }

    const body = (await request.json()) as { title?: string; text?: string };
    const title = body.title?.trim() ?? "";
    const text = body.text?.trim() ?? "";

    if (title.length < 3) {
      return NextResponse.json(
        { error: "Document title must be at least 3 characters long." },
        { status: 400 },
      );
    }

    if (text.length < 20) {
      return NextResponse.json(
        { error: "Document text must be at least 20 characters long." },
        { status: 400 },
      );
    }

    const result = await ingestTextDocument({
      lessonId: lesson.id,
      title,
      rawText: text,
      sourceType: "text",
    });

    return NextResponse.json(result, { status: 201 });
  } catch (error) {
    return NextResponse.json(
      {
        error:
          error instanceof Error ? error.message : "Could not ingest document.",
      },
      { status: 500 },
    );
  }
}
