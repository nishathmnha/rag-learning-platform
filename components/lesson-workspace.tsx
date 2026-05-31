"use client";

import { Fragment, useRef, useState } from "react";
import { useRouter } from "next/navigation";

type WorkspaceDocument = {
  id: string;
  title: string;
  fileName: string | null;
  sourceType: string;
  size: number | null;
  createdAt: string;
};

type WorkspaceGeneratedLesson = {
  id: string;
  content: string;
  sourceCount: number;
  createdAt: string;
};

type WorkspaceAssessmentQuestion = {
  id: string;
  question: string;
  options: string[];
  correctAnswer: string;
  explanation: string;
};

type WorkspaceAssessment = {
  id: string;
  title: string;
  createdAt: string;
  questions: WorkspaceAssessmentQuestion[];
};

type SourceReference = {
  documentId: string;
  documentTitle: string;
  chunkIndex: number;
  score: number;
};

type ChatMessage = {
  role: "user" | "assistant";
  content: string;
  sources?: SourceReference[];
};

type LessonWorkspaceProps = {
  lesson: {
    id: string;
    title: string;
    createdAt: string;
  };
  stats: {
    documentCount: number;
    chunkCount: number;
    generatedLessonCount: number;
    assessmentCount: number;
  };
  initialDocuments: WorkspaceDocument[];
  initialGeneratedLessons: WorkspaceGeneratedLesson[];
  initialAssessments: WorkspaceAssessment[];
};

type TabId = "overview" | "documents" | "lessons" | "assessments" | "chat";

type QuizSelections = Record<string, string>;

const tabs: { id: TabId; label: string }[] = [
  { id: "overview", label: "Overview" },
  { id: "documents", label: "Documents" },
  { id: "lessons", label: "Lessons" },
  { id: "assessments", label: "Assessments" },
  { id: "chat", label: "Chat" },
];

function renderInlineFormatting(text: string) {
  const parts = text.split(/(\*\*[^*]+\*\*)/g);

  return parts.map((part, index) => {
    if (part.startsWith("**") && part.endsWith("**")) {
      return (
        <strong key={`${part}-${index}`} className="font-semibold text-slate-950">
          {part.slice(2, -2)}
        </strong>
      );
    }

    return <Fragment key={`${part}-${index}`}>{part}</Fragment>;
  });
}

function FormattedLessonContent({ content }: { content: string }) {
  const lines = content.replace(/\r\n/g, "\n").split("\n");
  const blocks: Array<
    | { type: "heading"; text: string }
    | { type: "list"; items: string[] }
    | { type: "ordered-list"; items: string[] }
    | { type: "paragraph"; text: string }
    | { type: "divider" }
  > = [];

  for (let index = 0; index < lines.length; ) {
    const line = lines[index].trim();

    if (!line) {
      index += 1;
      continue;
    }

    if (/^(#{1,6}\s+)/.test(line)) {
      blocks.push({
        type: "heading",
        text: line.replace(/^#{1,6}\s+/, ""),
      });
      index += 1;
      continue;
    }

    if (/^- /.test(line)) {
      const items: string[] = [];

      while (index < lines.length && /^- /.test(lines[index].trim())) {
        items.push(lines[index].trim().replace(/^- /, ""));
        index += 1;
      }

      blocks.push({ type: "list", items });
      continue;
    }

    if (/^\d+\.\s+/.test(line)) {
      const items: string[] = [];

      while (index < lines.length && /^\d+\.\s+/.test(lines[index].trim())) {
        items.push(lines[index].trim().replace(/^\d+\.\s+/, ""));
        index += 1;
      }

      blocks.push({ type: "ordered-list", items });
      continue;
    }

    if (/^-{3,}$/.test(line)) {
      blocks.push({ type: "divider" });
      index += 1;
      continue;
    }

    const paragraphLines: string[] = [];

    while (index < lines.length) {
      const currentLine = lines[index].trim();

      if (
        !currentLine ||
        /^- /.test(currentLine) ||
        /^\d+\.\s+/.test(currentLine) ||
        /^-{3,}$/.test(currentLine) ||
        /^(#{1,6}\s+)/.test(currentLine)
      ) {
        break;
      }

      paragraphLines.push(currentLine);
      index += 1;
    }

    blocks.push({
      type: "paragraph",
      text: paragraphLines.join(" "),
    });
  }

  return (
    <div className="space-y-5">
      {blocks.map((block, index) => {
        if (block.type === "heading") {
          return (
            <h3
              key={`${block.text}-${index}`}
              className="text-xl font-semibold tracking-tight text-slate-950"
            >
              {renderInlineFormatting(block.text)}
            </h3>
          );
        }

        if (block.type === "list") {
          return (
            <ul
              key={`${block.items.join("-")}-${index}`}
              className="space-y-2 pl-5 text-sm leading-7 text-slate-700"
            >
              {block.items.map((item, itemIndex) => (
                <li key={`${item}-${itemIndex}`} className="list-disc">
                  {renderInlineFormatting(item)}
                </li>
              ))}
            </ul>
          );
        }

        if (block.type === "ordered-list") {
          return (
            <ol
              key={`${block.items.join("-")}-${index}`}
              className="space-y-2 pl-5 text-sm leading-7 text-slate-700"
            >
              {block.items.map((item, itemIndex) => (
                <li key={`${item}-${itemIndex}`} className="list-decimal">
                  {renderInlineFormatting(item)}
                </li>
              ))}
            </ol>
          );
        }

        if (block.type === "divider") {
          return <hr key={`divider-${index}`} className="border-slate-200" />;
        }

        return (
          <p
            key={`${block.text}-${index}`}
            className="text-sm leading-7 text-slate-700"
          >
            {renderInlineFormatting(block.text)}
          </p>
        );
      })}
    </div>
  );
}

export function LessonWorkspace({
  lesson,
  stats,
  initialDocuments,
  initialGeneratedLessons,
  initialAssessments,
}: LessonWorkspaceProps) {
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [activeTab, setActiveTab] = useState<TabId>("overview");
  const [documents, setDocuments] = useState(initialDocuments);
  const [workspaceStats, setWorkspaceStats] = useState(stats);
  const [generatedLessons, setGeneratedLessons] = useState(initialGeneratedLessons);
  const [selectedGeneratedLessonId, setSelectedGeneratedLessonId] = useState(
    initialGeneratedLessons[0]?.id ?? null,
  );
  const [assessments, setAssessments] = useState(initialAssessments);
  const [selectedAssessmentId, setSelectedAssessmentId] = useState(
    initialAssessments[0]?.id ?? null,
  );
  const [lessonSources, setLessonSources] = useState<SourceReference[]>([]);
  const [assessmentSources, setAssessmentSources] = useState<SourceReference[]>([]);
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([]);
  const [selectedQuizAnswers, setSelectedQuizAnswers] = useState<QuizSelections>({});
  const [hasSubmittedQuiz, setHasSubmittedQuiz] = useState(false);
  const [textDocumentTitle, setTextDocumentTitle] = useState("");
  const [textDocumentBody, setTextDocumentBody] = useState("");
  const [chatQuestion, setChatQuestion] = useState("");
  const [error, setError] = useState("");
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [isDragActive, setIsDragActive] = useState(false);
  const [isUploadingText, setIsUploadingText] = useState(false);
  const [isUploadingFiles, setIsUploadingFiles] = useState(false);
  const [isGeneratingLesson, setIsGeneratingLesson] = useState(false);
  const [isGeneratingQuiz, setIsGeneratingQuiz] = useState(false);
  const [isSendingChat, setIsSendingChat] = useState(false);

  function handleSelectedFiles(fileList: FileList | null) {
    if (!fileList) {
      return;
    }

    setSelectedFiles(Array.from(fileList));
  }

  async function refreshDocuments() {
    const response = await fetch(`/api/lessons/${lesson.id}/documents`);

    if (!response.ok) {
      return;
    }

    const payload = (await response.json()) as WorkspaceDocument[];
    setDocuments(
      payload.map((document) => ({
        ...document,
        createdAt: document.createdAt,
      })),
    );
    setWorkspaceStats((currentStats) => ({
      ...currentStats,
      documentCount: payload.length,
    }));
    router.refresh();
  }

  const generatedLesson =
    generatedLessons.find((item) => item.id === selectedGeneratedLessonId) ?? null;
  const assessment = assessments.find((item) => item.id === selectedAssessmentId) ?? null;
  const answeredQuestionCount = assessment
    ? assessment.questions.filter((question) => selectedQuizAnswers[question.id]).length
    : 0;
  const quizScore = assessment
    ? assessment.questions.filter(
        (question) => selectedQuizAnswers[question.id] === question.correctAnswer,
      ).length
    : 0;

  return (
    <div className="space-y-6">
      <section className="rounded-[2rem] border border-white/80 bg-white/90 p-7 shadow-[0_18px_45px_rgba(15,23,42,0.06)]">
        <div className="flex flex-col gap-6 xl:flex-row xl:items-center xl:justify-between">
          <div className="space-y-2">
            <p className="text-sm font-medium uppercase tracking-[0.3em] text-indigo-500">
              Lesson Workspace
            </p>
            <h1 className="text-4xl font-semibold tracking-tight text-slate-950">
              {lesson.title}
            </h1>
            <p className="text-sm text-slate-600">
              Created {new Date(lesson.createdAt).toLocaleDateString()}
            </p>
          </div>

          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {[
              { label: "Documents", value: workspaceStats.documentCount },
              { label: "Chunks", value: workspaceStats.chunkCount },
              { label: "Lessons", value: workspaceStats.generatedLessonCount },
              { label: "Quizzes", value: workspaceStats.assessmentCount },
            ].map((card) => (
              <div
                key={card.label}
                className="rounded-[1.25rem] bg-slate-50 px-4 py-4 text-center"
              >
                <p className="text-xs font-medium uppercase tracking-[0.2em] text-slate-500">
                  {card.label}
                </p>
                <p className="mt-2 text-2xl font-semibold text-slate-950">{card.value}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="mt-8 flex flex-wrap gap-2 border-b border-slate-200 pb-3">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              className={`rounded-full px-4 py-2 text-sm font-medium transition ${
                activeTab === tab.id
                  ? "bg-indigo-600 text-white shadow-[0_10px_20px_rgba(79,70,229,0.24)]"
                  : "text-slate-600 hover:bg-slate-100"
              }`}
              onClick={() => setActiveTab(tab.id)}
              type="button"
            >
              {tab.label}
            </button>
          ))}
        </div>
      </section>

      {error ? (
        <p className="rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-700">{error}</p>
      ) : null}

      {activeTab === "overview" ? (
        <section className="grid gap-6 lg:grid-cols-[1.4fr_1fr]">
          <article className="rounded-[2rem] border border-white/80 bg-white/90 p-6 shadow-[0_18px_45px_rgba(15,23,42,0.06)]">
            <h2 className="text-xl font-semibold text-slate-950">Workflow</h2>
            <div className="mt-5 grid gap-4 md:grid-cols-2">
              {[
                "Upload multiple PDF, DOCX, and TXT files under this lesson.",
                "Convert source documents into retrieval-ready chunks.",
                "Generate structured lessons grounded in your uploaded material.",
                "Create MCQ assessments and ask questions through chat.",
              ].map((item, index) => (
                <div
                  key={item}
                  className="rounded-[1.5rem] bg-slate-50 px-5 py-5"
                >
                  <p className="text-xs font-medium uppercase tracking-[0.2em] text-indigo-500">
                    Step 0{index + 1}
                  </p>
                  <p className="mt-3 text-sm leading-6 text-slate-700">{item}</p>
                </div>
              ))}
            </div>

            <div className="mt-6 grid gap-4 sm:grid-cols-3">
              <div className="rounded-[1.5rem] border border-slate-200 px-5 py-5">
                <p className="text-xs font-medium uppercase tracking-[0.2em] text-slate-500">
                  Corpus status
                </p>
                <p className="mt-3 text-lg font-semibold text-slate-950">
                  {workspaceStats.documentCount === 0
                    ? "Waiting for source files"
                    : `${workspaceStats.documentCount} document${
                        workspaceStats.documentCount === 1 ? "" : "s"
                      } indexed`}
                </p>
                <p className="mt-2 text-sm text-slate-600">
                  {workspaceStats.chunkCount} retrieval chunks are available for generation.
                </p>
              </div>

              <div className="rounded-[1.5rem] border border-slate-200 px-5 py-5">
                <p className="text-xs font-medium uppercase tracking-[0.2em] text-slate-500">
                  Lesson output
                </p>
                <p className="mt-3 text-lg font-semibold text-slate-950">
                  {generatedLesson ? "Latest lesson ready" : "No lesson generated yet"}
                </p>
                <p className="mt-2 text-sm text-slate-600">
                  Generate structured notes grounded only in the retrieved context.
                </p>
              </div>

              <div className="rounded-[1.5rem] border border-slate-200 px-5 py-5">
                <p className="text-xs font-medium uppercase tracking-[0.2em] text-slate-500">
                  Assessment output
                </p>
                <p className="mt-3 text-lg font-semibold text-slate-950">
                  {assessment ? `${assessment.questions.length} questions ready` : "No quiz yet"}
                </p>
                <p className="mt-2 text-sm text-slate-600">
                  Build a fresh MCQ set whenever the lesson corpus changes.
                </p>
              </div>
            </div>
          </article>

          <article className="rounded-[2rem] border border-white/80 bg-slate-950 p-6 text-white shadow-[0_18px_45px_rgba(15,23,42,0.18)]">
            <h2 className="text-xl font-semibold">Quick actions</h2>
            <div className="mt-5 grid gap-3">
              {[
                { label: "Add documents", tab: "documents" as TabId },
                { label: "Generate lesson", tab: "lessons" as TabId },
                { label: "Generate quiz", tab: "assessments" as TabId },
                { label: "Ask a question", tab: "chat" as TabId },
              ].map((action) => (
                <button
                  key={action.label}
                  className="rounded-full border border-white/15 bg-white/10 px-4 py-3 text-left text-sm font-medium text-white transition hover:bg-white/15"
                  onClick={() => setActiveTab(action.tab)}
                  type="button"
                >
                  {action.label}
                </button>
              ))}
            </div>
          </article>
        </section>
      ) : null}

      {activeTab === "documents" ? (
        <section className="grid gap-6 lg:grid-cols-[1.2fr_1fr]">
          <article className="rounded-[2rem] border border-white/80 bg-white/90 p-6 shadow-[0_18px_45px_rgba(15,23,42,0.06)]">
            <h2 className="text-xl font-semibold text-slate-950">Upload source documents</h2>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              Add multiple PDF, DOCX, or TXT files. You can also paste raw text
              directly when you do not have a file.
            </p>

            <form
              className="mt-6 space-y-4"
              onSubmit={async (event) => {
                event.preventDefault();
                setError("");

                if (selectedFiles.length === 0) {
                  setError("Choose at least one PDF, DOCX, or TXT file to upload.");
                  return;
                }

                setIsUploadingFiles(true);

                const formData = new FormData();
                selectedFiles.forEach((file) => {
                  formData.append("files", file);
                });

                const response = await fetch(`/api/lessons/${lesson.id}/documents`, {
                  method: "POST",
                  body: formData,
                });

                setIsUploadingFiles(false);

                if (!response.ok) {
                  const payload = (await response.json()) as { error?: string };
                  setError(payload.error ?? "Could not upload files.");
                  return;
                }

                const payload = (await response.json()) as {
                  documents: Array<{ chunkCount: number }>;
                };
                const uploadedChunkCount = payload.documents.reduce(
                  (total, document) => total + document.chunkCount,
                  0,
                );

                setWorkspaceStats((currentStats) => ({
                  ...currentStats,
                  chunkCount: currentStats.chunkCount + uploadedChunkCount,
                }));
                setSelectedFiles([]);
                if (fileInputRef.current) {
                  fileInputRef.current.value = "";
                }
                await refreshDocuments();
              }}
            >
              <input
                ref={fileInputRef}
                className="sr-only"
                multiple
                name="files"
                type="file"
                accept=".pdf,.docx,.txt,text/plain,application/pdf,application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                onChange={(event) => handleSelectedFiles(event.target.files)}
              />

              <div
                className={`flex min-h-48 cursor-pointer flex-col items-center justify-center rounded-[1.5rem] border border-dashed px-6 py-8 text-center transition ${
                  isDragActive
                    ? "border-indigo-400 bg-indigo-100/80"
                    : "border-indigo-200 bg-indigo-50/50"
                }`}
                onClick={() => fileInputRef.current?.click()}
                onDragEnter={(event) => {
                  event.preventDefault();
                  setIsDragActive(true);
                }}
                onDragLeave={(event) => {
                  event.preventDefault();
                  setIsDragActive(false);
                }}
                onDragOver={(event) => {
                  event.preventDefault();
                  setIsDragActive(true);
                }}
                onDrop={(event) => {
                  event.preventDefault();
                  setIsDragActive(false);
                  handleSelectedFiles(event.dataTransfer.files);
                }}
                role="button"
                tabIndex={0}
                onKeyDown={(event) => {
                  if (event.key === "Enter" || event.key === " ") {
                    event.preventDefault();
                    fileInputRef.current?.click();
                  }
                }}
              >
                <span className="text-sm font-medium text-slate-950">
                  Drag files here or choose from your computer
                </span>
                <span className="mt-2 text-sm text-slate-500">
                  PDF, DOCX, and TXT are supported
                </span>
                <span className="mt-4 rounded-full bg-white px-4 py-2 text-xs font-medium text-indigo-600 shadow-sm">
                  Choose files
                </span>
              </div>

              {selectedFiles.length > 0 ? (
                <div className="rounded-[1.25rem] border border-slate-200 bg-slate-50 px-4 py-4">
                  <div className="flex items-center justify-between gap-3">
                    <p className="text-sm font-medium text-slate-900">
                      {selectedFiles.length} file{selectedFiles.length === 1 ? "" : "s"} selected
                    </p>
                    <button
                      className="text-sm font-medium text-slate-500 transition hover:text-slate-700"
                      onClick={() => {
                        setSelectedFiles([]);
                        if (fileInputRef.current) {
                          fileInputRef.current.value = "";
                        }
                      }}
                      type="button"
                    >
                      Clear
                    </button>
                  </div>

                  <div className="mt-3 flex flex-wrap gap-2">
                    {selectedFiles.map((file) => (
                      <span
                        key={`${file.name}-${file.lastModified}`}
                        className="rounded-full bg-white px-3 py-2 text-xs text-slate-700 shadow-sm"
                      >
                        {file.name} - {(file.size / 1024).toFixed(1)} KB
                      </span>
                    ))}
                  </div>
                </div>
              ) : null}

              <button
                className="inline-flex rounded-full bg-slate-950 px-5 py-3 text-sm font-medium text-white transition hover:bg-slate-800 disabled:opacity-60"
                disabled={isUploadingFiles || selectedFiles.length === 0}
                type="submit"
              >
                {isUploadingFiles ? "Uploading..." : "Upload files"}
              </button>
            </form>

            <div className="mt-8 border-t border-slate-200 pt-8">
              <h3 className="text-lg font-semibold text-slate-950">Paste raw text</h3>
              <form
                className="mt-4 space-y-4"
                onSubmit={async (event) => {
                  event.preventDefault();
                  setError("");
                  setIsUploadingText(true);

                  const response = await fetch(`/api/lessons/${lesson.id}/documents`, {
                    method: "POST",
                    headers: {
                      "Content-Type": "application/json",
                    },
                    body: JSON.stringify({
                      title: textDocumentTitle,
                      text: textDocumentBody,
                    }),
                  });

                  setIsUploadingText(false);

                  if (!response.ok) {
                    const payload = (await response.json()) as { error?: string };
                    setError(payload.error ?? "Could not save text document.");
                    return;
                  }

                  const payload = (await response.json()) as { chunkCount: number };
                  setWorkspaceStats((currentStats) => ({
                    ...currentStats,
                    chunkCount: currentStats.chunkCount + payload.chunkCount,
                  }));
                  setTextDocumentTitle("");
                  setTextDocumentBody("");
                  await refreshDocuments();
                }}
              >
                <input
                  className="w-full rounded-2xl border border-slate-200 px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-indigo-400"
                  onChange={(event) => setTextDocumentTitle(event.target.value)}
                  placeholder="Document title"
                  required
                  type="text"
                  value={textDocumentTitle}
                />
                <textarea
                  className="min-h-44 w-full rounded-2xl border border-slate-200 px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-indigo-400"
                  onChange={(event) => setTextDocumentBody(event.target.value)}
                  placeholder="Paste source text here..."
                  required
                  value={textDocumentBody}
                />
                <button
                  className="inline-flex rounded-full border border-slate-200 px-5 py-3 text-sm font-medium text-slate-700 transition hover:bg-slate-50 disabled:opacity-60"
                  disabled={isUploadingText}
                  type="submit"
                >
                  {isUploadingText ? "Saving..." : "Save text document"}
                </button>
              </form>
            </div>
          </article>

          <article className="rounded-[2rem] border border-white/80 bg-white/90 p-6 shadow-[0_18px_45px_rgba(15,23,42,0.06)]">
            <h2 className="text-xl font-semibold text-slate-950">Attached documents</h2>
            <div className="mt-5 space-y-3">
              {documents.length === 0 ? (
                <p className="rounded-2xl border border-dashed border-slate-200 px-4 py-6 text-sm text-slate-500">
                  No documents uploaded yet.
                </p>
              ) : (
                documents.map((document) => (
                  <div
                    key={document.id}
                    className="rounded-[1.25rem] border border-slate-200 px-4 py-4"
                  >
                    <p className="font-medium text-slate-900">{document.title}</p>
                    <div className="mt-2 flex flex-wrap gap-2 text-xs text-slate-500">
                      <span className="rounded-full bg-slate-100 px-3 py-1">
                        {document.sourceType.toUpperCase()}
                      </span>
                      {document.fileName ? (
                        <span className="rounded-full bg-slate-100 px-3 py-1">
                          {document.fileName}
                        </span>
                      ) : null}
                      {document.size ? (
                        <span className="rounded-full bg-slate-100 px-3 py-1">
                          {(document.size / 1024).toFixed(1)} KB
                        </span>
                      ) : null}
                    </div>
                  </div>
                ))
              )}
            </div>
          </article>
        </section>
      ) : null}

      {activeTab === "lessons" ? (
        <section className="rounded-[2rem] border border-white/80 bg-white/90 p-6 shadow-[0_18px_45px_rgba(15,23,42,0.06)]">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h2 className="text-xl font-semibold text-slate-950">Generated lesson</h2>
              <p className="mt-2 text-sm text-slate-600">
                Use retrieval across all documents in this lesson to build grounded notes.
              </p>
            </div>
            <button
              className="inline-flex rounded-full bg-indigo-600 px-5 py-3 text-sm font-medium text-white transition hover:bg-indigo-500 disabled:opacity-60"
              disabled={isGeneratingLesson}
              onClick={async () => {
                setError("");
                setIsGeneratingLesson(true);

                const response = await fetch(
                  `/api/lessons/${lesson.id}/generate-lesson`,
                  {
                    method: "POST",
                  },
                );

                setIsGeneratingLesson(false);

                if (!response.ok) {
                  const payload = (await response.json()) as { error?: string };
                  setError(payload.error ?? "Could not generate lesson.");
                  return;
                }

                const payload = (await response.json()) as {
                  id: string;
                  content: string;
                  sourceCount: number;
                  chunks: SourceReference[];
                };

                const nextGeneratedLesson = {
                  id: payload.id,
                  content: payload.content,
                  sourceCount: payload.sourceCount,
                  createdAt: new Date().toISOString(),
                };

                setGeneratedLessons((currentLessons) => [
                  nextGeneratedLesson,
                  ...currentLessons,
                ]);
                setSelectedGeneratedLessonId(payload.id);
                setLessonSources(payload.chunks);
                setWorkspaceStats((currentStats) => ({
                  ...currentStats,
                  generatedLessonCount: currentStats.generatedLessonCount + 1,
                }));
                router.refresh();
              }}
              type="button"
            >
              {isGeneratingLesson ? "Generating..." : "Generate lesson"}
            </button>
          </div>

          {generatedLesson ? (
            <div className="mt-6 grid gap-6 lg:grid-cols-[280px_1fr]">
              <aside className="rounded-[1.5rem] bg-slate-50 p-4">
                <p className="text-xs font-medium uppercase tracking-[0.2em] text-indigo-500">
                  Lesson History
                </p>
                <div className="mt-4 space-y-3">
                  {generatedLessons.map((lessonItem, index) => (
                    <button
                      key={lessonItem.id}
                      className={`w-full rounded-[1.25rem] border px-4 py-4 text-left transition ${
                        lessonItem.id === generatedLesson.id
                          ? "border-indigo-200 bg-white shadow-sm"
                          : "border-transparent bg-white/60 hover:border-slate-200 hover:bg-white"
                      }`}
                      onClick={() => {
                        setSelectedGeneratedLessonId(lessonItem.id);
                        setLessonSources([]);
                      }}
                      type="button"
                    >
                      <p className="text-xs font-medium uppercase tracking-[0.2em] text-slate-500">
                        Lesson {generatedLessons.length - index}
                      </p>
                      <p className="mt-2 text-sm font-medium text-slate-900">
                        {new Date(lessonItem.createdAt).toLocaleString()}
                      </p>
                      <p className="mt-2 text-xs text-slate-500">
                        {lessonItem.sourceCount} source chunks used
                      </p>
                    </button>
                  ))}
                </div>
              </aside>

              <article className="rounded-[1.5rem] border border-slate-200 px-5 py-5">
                <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-200 pb-4">
                  <div>
                    <p className="text-sm font-medium text-slate-900">
                      Generated {new Date(generatedLesson.createdAt).toLocaleString()}
                    </p>
                    <p className="mt-1 text-sm text-slate-600">
                      {generatedLesson.sourceCount} source chunks used for this lesson version.
                    </p>
                  </div>
                  <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-medium text-slate-700">
                    Version {generatedLessons.findIndex((item) => item.id === generatedLesson.id) + 1}
                  </span>
                </div>

                <div className="mt-5">
                  <FormattedLessonContent content={generatedLesson.content} />
                </div>
                {lessonSources.length > 0 ? (
                  <div className="mt-6 border-t border-slate-200 pt-4">
                    <p className="text-sm font-medium text-slate-900">Retrieved sources</p>
                    <div className="mt-3 flex flex-wrap gap-2">
                      {lessonSources.map((source) => (
                        <span
                          key={`${source.documentId}-${source.chunkIndex}`}
                          className="rounded-full bg-slate-100 px-3 py-1 text-xs text-slate-700"
                        >
                          {source.documentTitle} - chunk {source.chunkIndex + 1}
                        </span>
                      ))}
                    </div>
                  </div>
                ) : (
                  <p className="mt-6 border-t border-slate-200 pt-4 text-sm text-slate-500">
                    Select the latest generated lesson to see the retrieval source chips for this session.
                  </p>
                )}
              </article>
            </div>
          ) : (
            <p className="mt-6 rounded-2xl border border-dashed border-slate-200 px-4 py-6 text-sm text-slate-500">
              Generate the first lesson once documents have been attached.
            </p>
          )}
        </section>
      ) : null}

      {activeTab === "assessments" ? (
        <section className="rounded-[2rem] border border-white/80 bg-white/90 p-6 shadow-[0_18px_45px_rgba(15,23,42,0.06)]">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h2 className="text-xl font-semibold text-slate-950">MCQ assessment</h2>
              <p className="mt-2 text-sm text-slate-600">
                Generate retrieval-grounded quiz questions from the lesson corpus.
              </p>
            </div>
            <button
              className="inline-flex rounded-full bg-indigo-600 px-5 py-3 text-sm font-medium text-white transition hover:bg-indigo-500 disabled:opacity-60"
              disabled={isGeneratingQuiz}
              onClick={async () => {
                setError("");
                setIsGeneratingQuiz(true);

                const response = await fetch(
                  `/api/lessons/${lesson.id}/generate-mcq`,
                  {
                    method: "POST",
                    headers: {
                      "Content-Type": "application/json",
                    },
                    body: JSON.stringify({ questionCount: 5 }),
                  },
                );

                setIsGeneratingQuiz(false);

                if (!response.ok) {
                  const payload = (await response.json()) as { error?: string };
                  setError(payload.error ?? "Could not generate quiz.");
                  return;
                }

                const payload = (await response.json()) as {
                  id: string;
                  title: string;
                  questions: WorkspaceAssessmentQuestion[];
                  sources: SourceReference[];
                };

                const nextAssessment = {
                  id: payload.id,
                  title: payload.title,
                  createdAt: new Date().toISOString(),
                  questions: payload.questions,
                };

                setAssessments((currentAssessments) => [
                  nextAssessment,
                  ...currentAssessments,
                ]);
                setSelectedAssessmentId(payload.id);
                setSelectedQuizAnswers({});
                setHasSubmittedQuiz(false);
                setAssessmentSources(payload.sources);
                setWorkspaceStats((currentStats) => ({
                  ...currentStats,
                  assessmentCount: currentStats.assessmentCount + 1,
                }));
                router.refresh();
              }}
              type="button"
            >
              {isGeneratingQuiz ? "Generating..." : "Generate MCQ"}
            </button>
          </div>

          {assessment ? (
            <div className="mt-6 grid gap-6 lg:grid-cols-[280px_1fr]">
              <aside className="rounded-[1.5rem] bg-slate-50 p-4">
                <p className="text-xs font-medium uppercase tracking-[0.2em] text-indigo-500">
                  Assessment History
                </p>
                <div className="mt-4 space-y-3">
                  {assessments.map((assessmentItem, index) => (
                    <button
                      key={assessmentItem.id}
                      className={`w-full rounded-[1.25rem] border px-4 py-4 text-left transition ${
                        assessmentItem.id === assessment.id
                          ? "border-indigo-200 bg-white shadow-sm"
                          : "border-transparent bg-white/60 hover:border-slate-200 hover:bg-white"
                      }`}
                      onClick={() => {
                        setSelectedAssessmentId(assessmentItem.id);
                        setSelectedQuizAnswers({});
                        setHasSubmittedQuiz(false);
                        setAssessmentSources([]);
                      }}
                      type="button"
                    >
                      <p className="text-xs font-medium uppercase tracking-[0.2em] text-slate-500">
                        Quiz {assessments.length - index}
                      </p>
                      <p className="mt-2 text-sm font-medium text-slate-900">
                        {new Date(assessmentItem.createdAt).toLocaleString()}
                      </p>
                      <p className="mt-2 text-xs text-slate-500">
                        {assessmentItem.questions.length} questions
                      </p>
                    </button>
                  ))}
                </div>
              </aside>

              <div className="space-y-4">
                <div className="flex flex-col gap-3 rounded-[1.5rem] bg-slate-50 px-5 py-5 sm:flex-row sm:items-center sm:justify-between">
                  <div>
                    <p className="text-sm font-medium text-slate-950">{assessment.title}</p>
                    <p className="mt-1 text-sm text-slate-600">
                      Answer all questions, then submit to see your score and explanations.
                    </p>
                  </div>

                  {hasSubmittedQuiz ? (
                    <div className="rounded-full bg-indigo-600 px-4 py-2 text-sm font-medium text-white">
                      Score: {quizScore}/{assessment.questions.length}
                    </div>
                  ) : (
                    <div className="rounded-full bg-white px-4 py-2 text-sm text-slate-600">
                      {answeredQuestionCount}/{assessment.questions.length} answered
                    </div>
                  )}
                </div>

                {assessment.questions.map((question, index) => (
                  <article
                    key={question.id}
                    className="rounded-[1.5rem] border border-slate-200 px-5 py-5"
                  >
                    <p className="text-sm font-medium text-indigo-500">
                      Question {index + 1}
                    </p>
                    <h3 className="mt-2 font-medium text-slate-950">{question.question}</h3>
                    <ul className="mt-4 space-y-2">
                      {question.options.map((option) => (
                        <button
                          key={option}
                          className={`block w-full rounded-2xl border px-4 py-3 text-left text-sm transition ${
                            hasSubmittedQuiz
                              ? option === question.correctAnswer
                                ? "border-emerald-300 bg-emerald-50 text-emerald-700"
                                : selectedQuizAnswers[question.id] === option
                                  ? "border-red-300 bg-red-50 text-red-700"
                                  : "border-slate-200 text-slate-700"
                              : selectedQuizAnswers[question.id] === option
                                ? "border-indigo-300 bg-indigo-50 text-indigo-700"
                                : "border-slate-200 text-slate-700 hover:border-indigo-200 hover:bg-slate-50"
                          }`}
                          disabled={hasSubmittedQuiz}
                          onClick={() => {
                            if (hasSubmittedQuiz) {
                              return;
                            }

                            setSelectedQuizAnswers((currentSelections) => ({
                              ...currentSelections,
                              [question.id]: option,
                            }));
                          }}
                          type="button"
                        >
                          {option}
                        </button>
                      ))}
                    </ul>

                    {hasSubmittedQuiz ? (
                      <div className="mt-4 space-y-2">
                        <p className="text-sm font-medium text-slate-900">
                          Your answer: {selectedQuizAnswers[question.id] ?? "No answer selected"}
                        </p>
                        <p className="text-sm text-slate-600">{question.explanation}</p>
                      </div>
                    ) : null}
                  </article>
                ))}

                <div className="flex flex-col gap-3 sm:flex-row">
                  {!hasSubmittedQuiz ? (
                    <button
                      className="inline-flex rounded-full bg-slate-950 px-5 py-3 text-sm font-medium text-white transition hover:bg-slate-800 disabled:opacity-60"
                      disabled={!assessment || answeredQuestionCount !== assessment.questions.length}
                      onClick={() => setHasSubmittedQuiz(true)}
                      type="button"
                    >
                      Submit answers
                    </button>
                  ) : (
                    <button
                      className="inline-flex rounded-full border border-slate-200 px-5 py-3 text-sm font-medium text-slate-700 transition hover:bg-slate-50"
                      onClick={() => {
                        setSelectedQuizAnswers({});
                        setHasSubmittedQuiz(false);
                      }}
                      type="button"
                    >
                      Try again
                    </button>
                  )}
                </div>

                {assessmentSources.length > 0 ? (
                  <div className="rounded-[1.5rem] bg-slate-50 px-4 py-4">
                    <p className="text-sm font-medium text-slate-900">Retrieved sources</p>
                    <div className="mt-3 flex flex-wrap gap-2">
                      {assessmentSources.map((source) => (
                        <span
                          key={`${source.documentId}-${source.chunkIndex}`}
                          className="rounded-full bg-white px-3 py-1 text-xs text-slate-700"
                        >
                          {source.documentTitle} - chunk {source.chunkIndex + 1}
                        </span>
                      ))}
                    </div>
                  </div>
                ) : (
                  <p className="rounded-[1.5rem] bg-slate-50 px-4 py-4 text-sm text-slate-500">
                    Select the latest generated quiz to see the retrieval source chips for this session.
                  </p>
                )}
              </div>
            </div>
          ) : (
            <p className="mt-6 rounded-2xl border border-dashed border-slate-200 px-4 py-6 text-sm text-slate-500">
              No assessment yet. Generate one after uploading source material.
            </p>
          )}
        </section>
      ) : null}

      {activeTab === "chat" ? (
        <section className="rounded-[2rem] border border-white/80 bg-white/90 p-6 shadow-[0_18px_45px_rgba(15,23,42,0.06)]">
          <h2 className="text-xl font-semibold text-slate-950">Chat with documents</h2>
          <p className="mt-2 text-sm text-slate-600">
            Ask questions about this lesson and the system will retrieve relevant chunks before answering.
          </p>

          <div className="mt-6 space-y-4">
            {chatMessages.length === 0 ? (
              <p className="rounded-2xl border border-dashed border-slate-200 px-4 py-6 text-sm text-slate-500">
                No questions yet. Ask something about the uploaded material.
              </p>
            ) : (
              chatMessages.map((message, index) => (
                <div
                  key={`${message.role}-${index}`}
                  className={`rounded-[1.5rem] px-5 py-4 ${
                    message.role === "user"
                      ? "ml-auto max-w-2xl bg-slate-950 text-white"
                      : "max-w-3xl border border-slate-200 bg-slate-50 text-slate-700"
                  }`}
                >
                  {message.role === "user" ? (
                    <p className="whitespace-pre-wrap text-sm leading-7">{message.content}</p>
                  ) : (
                    <FormattedLessonContent content={message.content} />
                  )}
                  {message.sources && message.sources.length > 0 ? (
                    <div className="mt-4 border-t border-slate-200 pt-4">
                      <p className="mb-3 text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">
                        Sources
                      </p>
                      <div className="flex flex-wrap gap-2">
                        {message.sources.map((source) => (
                          <span
                            key={`${source.documentId}-${source.chunkIndex}`}
                            className="rounded-full bg-white/80 px-3 py-1 text-xs text-slate-700"
                          >
                            {source.documentTitle} - chunk {source.chunkIndex + 1}
                          </span>
                        ))}
                      </div>
                    </div>
                  ) : null}
                </div>
              ))
            )}
          </div>

          <form
            className="mt-6 flex flex-col gap-3 sm:flex-row"
            onSubmit={async (event) => {
              event.preventDefault();
              setError("");
              const trimmedQuestion = chatQuestion.trim();

              if (trimmedQuestion.length < 3) {
                setError("Question must be at least 3 characters long.");
                return;
              }

              const nextMessages = [
                ...chatMessages,
                { role: "user", content: trimmedQuestion } satisfies ChatMessage,
              ];
              setChatMessages(nextMessages);
              setChatQuestion("");
              setIsSendingChat(true);

              const response = await fetch(`/api/lessons/${lesson.id}/chat`, {
                method: "POST",
                headers: {
                  "Content-Type": "application/json",
                },
                body: JSON.stringify({ question: trimmedQuestion }),
              });

              setIsSendingChat(false);

              if (!response.ok) {
                const payload = (await response.json()) as { error?: string };
                setError(payload.error ?? "Could not answer question.");
                return;
              }

              const payload = (await response.json()) as {
                answer: string;
                sources: SourceReference[];
              };

              setChatMessages([
                ...nextMessages,
                {
                  role: "assistant",
                  content: payload.answer,
                  sources: payload.sources,
                },
              ]);
            }}
          >
            <input
              className="w-full rounded-full border border-slate-200 px-5 py-3 text-sm text-slate-900 outline-none transition focus:border-indigo-400"
              onChange={(event) => setChatQuestion(event.target.value)}
              placeholder="Ask anything about your lesson documents..."
              type="text"
              value={chatQuestion}
            />
            <button
              className="inline-flex rounded-full bg-slate-950 px-5 py-3 text-sm font-medium text-white transition hover:bg-slate-800 disabled:opacity-60"
              disabled={isSendingChat}
              type="submit"
            >
              {isSendingChat ? "Thinking..." : "Send"}
            </button>
          </form>
        </section>
      ) : null}
    </div>
  );
}
