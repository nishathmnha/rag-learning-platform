import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { getServerSession } from "next-auth";

import { authOptions } from "@/auth";
import { LessonWorkspace } from "@/components/lesson-workspace";
import { prisma } from "@/lib/prisma";

type LessonPageProps = {
  params: Promise<{
    id: string;
  }>;
};

export default async function LessonPage({ params }: LessonPageProps) {
  const session = await getServerSession(authOptions);

  if (!session?.user?.id) {
    redirect("/login");
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
      generatedLessons: {
        orderBy: {
          createdAt: "desc",
        },
      },
      assessments: {
        orderBy: {
          createdAt: "desc",
        },
        include: {
          questions: {
            orderBy: {
              questionIndex: "asc",
            },
          },
        },
      },
      _count: {
        select: {
          documents: true,
          chunks: true,
          generatedLessons: true,
          assessments: true,
        },
      },
    },
  });

  if (!lesson) {
    notFound();
  }

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top_right,_rgba(99,102,241,0.10),_transparent_35%),linear-gradient(180deg,#f8fafc_0%,#eef2ff_100%)] px-6 py-12">
      <div className="mx-auto max-w-6xl space-y-6">
        <Link
          className="inline-flex text-sm font-medium text-indigo-600 transition hover:text-indigo-500"
          href="/dashboard"
        >
          Back to dashboard
        </Link>

        <LessonWorkspace
          initialAssessments={lesson.assessments.map((assessment) => ({
            id: assessment.id,
            title: assessment.title,
            createdAt: assessment.createdAt.toISOString(),
            questions: assessment.questions.map((question) => ({
              id: question.id,
              question: question.question,
              options: Array.isArray(question.options)
                ? (question.options as string[])
                : [],
              correctAnswer: question.correctAnswer,
              explanation: question.explanation,
            })),
          }))}
          initialDocuments={lesson.documents.map((document) => ({
            id: document.id,
            title: document.title,
            fileName: document.fileName,
            sourceType: document.sourceType,
            size: document.size,
            createdAt: document.createdAt.toISOString(),
          }))}
          initialGeneratedLessons={lesson.generatedLessons.map((generatedLesson) => ({
            id: generatedLesson.id,
            content: generatedLesson.content,
            sourceCount: generatedLesson.sourceCount,
            createdAt: generatedLesson.createdAt.toISOString(),
          }))}
          lesson={{
            id: lesson.id,
            title: lesson.title,
            createdAt: lesson.createdAt.toISOString(),
          }}
          stats={{
            assessmentCount: lesson._count.assessments,
            chunkCount: lesson._count.chunks,
            documentCount: lesson._count.documents,
            generatedLessonCount: lesson._count.generatedLessons,
          }}
        />
      </div>
    </main>
  );
}
