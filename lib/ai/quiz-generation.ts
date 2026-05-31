import { getOpenAIClient, openAIModels } from "@/lib/ai/openai";

type QuizGenerationInput = {
  lessonTitle: string;
  contextChunks: string[];
  questionCount?: number;
};

export type GeneratedQuizQuestion = {
  question: string;
  options: string[];
  correctAnswer: string;
  explanation: string;
};

function extractJsonPayload(rawText: string) {
  const trimmed = rawText.trim();

  if (trimmed.startsWith("{") && trimmed.endsWith("}")) {
    return trimmed;
  }

  const fenceMatch = trimmed.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);

  if (fenceMatch?.[1]) {
    return fenceMatch[1].trim();
  }

  const firstBrace = trimmed.indexOf("{");
  const lastBrace = trimmed.lastIndexOf("}");

  if (firstBrace >= 0 && lastBrace > firstBrace) {
    return trimmed.slice(firstBrace, lastBrace + 1);
  }

  return trimmed;
}

function normalizeQuestions(questions: GeneratedQuizQuestion[]) {
  return questions
    .map((question) => ({
      question: question.question?.trim() ?? "",
      options: Array.isArray(question.options)
        ? question.options
            .map((option) => option?.trim() ?? "")
            .filter((option) => option.length > 0)
        : [],
      correctAnswer: question.correctAnswer?.trim() ?? "",
      explanation: question.explanation?.trim() ?? "",
    }))
    .filter((question) => question.question.length > 0);
}

function validateQuestions(
  questions: GeneratedQuizQuestion[],
  questionCount: number,
) {
  if (!Array.isArray(questions) || questions.length === 0) {
    throw new Error("Quiz generation returned no questions.");
  }

  if (questions.length < Math.min(questionCount, 3)) {
    throw new Error("Quiz generation returned too few questions.");
  }

  for (const question of questions) {
    if (question.options.length !== 4) {
      throw new Error("Each quiz question must have exactly 4 options.");
    }

    if (!question.options.includes(question.correctAnswer)) {
      throw new Error("Each correctAnswer must match one of the options exactly.");
    }

    if (question.explanation.length < 12) {
      throw new Error("Each quiz question must include a usable explanation.");
    }
  }
}

export async function generateQuizFromContext({
  lessonTitle,
  contextChunks,
  questionCount = 5,
}: QuizGenerationInput) {
  const client = getOpenAIClient();

  const context = contextChunks
    .map((chunk, index) => `Source ${index + 1}:\n${chunk}`)
    .join("\n\n");

  let lastError: Error | null = null;

  for (let attempt = 1; attempt <= 3; attempt += 1) {
    try {
      const response = await client.responses.create({
        model: openAIModels.generation,
        input: [
          {
            role: "system",
            content: [
              {
                type: "input_text",
                text:
                  "You generate multiple choice quizzes using only the provided context. Return strict JSON with a top-level `questions` array. Each question must have exactly 4 options. The `correctAnswer` value must equal one of the option strings exactly. Do not wrap the JSON in markdown fences.",
              },
            ],
          },
          {
            role: "user",
            content: [
              {
                type: "input_text",
                text: `Create ${questionCount} MCQs for the lesson "${lessonTitle}". Use only this context:\n\n${context}\n\nReturn JSON in this shape:\n{"questions":[{"question":"...","options":["Option A","Option B","Option C","Option D"],"correctAnswer":"Option B","explanation":"..."}]}`,
              },
            ],
          },
        ],
      });

      const parsed = JSON.parse(extractJsonPayload(response.output_text)) as {
        questions?: GeneratedQuizQuestion[];
      };

      const normalizedQuestions = normalizeQuestions(parsed.questions ?? []);
      validateQuestions(normalizedQuestions, questionCount);

      return normalizedQuestions.slice(0, questionCount);
    } catch (error) {
      lastError =
        error instanceof Error
          ? error
          : new Error("Quiz generation returned an invalid response.");
    }
  }

  throw lastError ?? new Error("Quiz generation failed after multiple attempts.");
}
