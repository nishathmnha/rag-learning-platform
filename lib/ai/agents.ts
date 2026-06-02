import { Output, ToolLoopAgent, stepCountIs } from "ai";
import { z } from "zod";

import { GeneratedQuizQuestion } from "@/lib/ai/quiz-generation";
import { getOpenAILanguageModel } from "@/lib/ai/openai";
import {
  createLessonAgentTools,
  LessonContextToolResult,
} from "@/lib/ai/tools";

const quizQuestionSchema = z
  .object({
    question: z.string().trim().min(1),
    options: z.array(z.string().trim().min(1)).length(4),
    correctAnswer: z.string().trim().min(1),
    explanation: z.string().trim().min(12),
  })
  .refine((question) => question.options.includes(question.correctAnswer), {
    message: "correctAnswer must exactly match one of the options.",
    path: ["correctAnswer"],
  });

const quizOutputSchema = z.object({
  questions: z.array(quizQuestionSchema).min(1),
});

type CapturedContext = {
  relevantChunks: LessonContextToolResult["chunks"];
};

function createContextCapture() {
  const capture: CapturedContext = {
    relevantChunks: [],
  };

  return {
    capture,
    onStepFinish: ({
      toolResults,
    }: {
      toolResults: Array<{
        toolName: string;
        output: unknown;
      }>;
    }) => {
      for (const toolResult of toolResults) {
        if (toolResult.toolName !== "get_lesson_context") {
          continue;
        }

        const parsed = toolResult.output as LessonContextToolResult;

        if (Array.isArray(parsed?.chunks) && parsed.chunks.length > 0) {
          capture.relevantChunks = parsed.chunks;
        }
      }
    },
  };
}

function createGroundedAgent({
  lessonId,
  defaultQuery,
  defaultLimit,
  instructions,
  output,
}: {
  lessonId: string;
  defaultQuery: string;
  defaultLimit: number;
  instructions: string;
  output?: unknown;
}) {
  return new ToolLoopAgent({
    model: getOpenAILanguageModel(),
    instructions,
    tools: createLessonAgentTools({
      lessonId,
      defaultQuery,
      defaultLimit,
    }),
    output: output as never,
    stopWhen: stepCountIs(5),
    maxRetries: 1,
  });
}

export async function generateLessonWithAgent({
  lessonId,
  lessonTitle,
}: {
  lessonId: string;
  lessonTitle: string;
}) {
  const { capture, onStepFinish } = createContextCapture();
  const agent = createGroundedAgent({
    lessonId,
    defaultQuery: lessonTitle,
    defaultLimit: 5,
    instructions:
      "You are a grounded lesson-writing agent. Before writing the lesson, call get_lesson_context exactly once. You may call get_lesson_sources if you need to inspect source coverage. Use only tool results, never outside knowledge. If the sources are insufficient, explicitly say what is missing. Return plain text only with these headings exactly on their own lines: Introduction:, Key Concepts:, Examples:, Summary:.",
  });

  const result = await agent.generate({
    prompt: `Create a detailed lesson for "${lessonTitle}".

Requirements:
- Make the lesson substantial and useful, roughly 700 to 1200 words when the context supports it.
- Under Key Concepts, explain multiple important points in depth.
- Under Examples, include realistic examples grounded in the context.
- Keep paragraphs short and readable, usually 2 to 4 sentences.
- Prefer hyphen bullet points for grouped ideas unless sequence matters.
- If you use numbered lists, keep them in ascending order and do not leave blank lines between list items.
- Do not use markdown bold or decorative separators.`,
    onStepFinish,
  });

  return {
    content: result.text,
    relevantChunks: capture.relevantChunks,
  };
}

export async function generateQuizWithAgent({
  lessonId,
  lessonTitle,
  questionCount,
}: {
  lessonId: string;
  lessonTitle: string;
  questionCount: number;
}) {
  const { capture, onStepFinish } = createContextCapture();
  const agent = new ToolLoopAgent({
    model: getOpenAILanguageModel(),
    instructions:
      "You are a grounded quiz-authoring agent. Before writing questions, call get_lesson_context exactly once. You may call get_lesson_sources if needed to inspect document coverage. Use only tool results, never outside knowledge. Return a questions array where each item has question, options, correctAnswer, and explanation.",
    tools: createLessonAgentTools({
      lessonId,
      defaultQuery: lessonTitle,
      defaultLimit: 8,
    }),
    output: Output.object({
      schema: quizOutputSchema,
    }),
    stopWhen: stepCountIs(5),
    maxRetries: 1,
  });

  const result = await agent.generate({
    prompt: `Create ${questionCount} multiple-choice questions for the lesson "${lessonTitle}".

Requirements:
- Each question must have exactly 4 options.
- correctAnswer must match one option string exactly.
- explanation must clearly justify the correct answer.
- Keep the questions grounded in the retrieved lesson context.`,
    onStepFinish,
  });

  return {
    questions: result.output.questions.slice(0, questionCount) satisfies GeneratedQuizQuestion[],
    relevantChunks: capture.relevantChunks,
  };
}

export async function answerLessonQuestionWithAgent({
  lessonId,
  lessonTitle,
  question,
}: {
  lessonId: string;
  lessonTitle: string;
  question: string;
}) {
  const { capture, onStepFinish } = createContextCapture();
  const agent = createGroundedAgent({
    lessonId,
    defaultQuery: question,
    defaultLimit: 6,
    instructions:
      "You are a grounded lesson Q&A agent. Before answering, call get_lesson_context exactly once. You may call get_lesson_sources if you need to inspect source coverage. Use only tool results. If the answer is not in the sources, clearly say that the lesson context does not contain enough information.",
  });

  const result = await agent.generate({
    prompt: `Lesson: "${lessonTitle}"
Question: ${question}`,
    onStepFinish,
  });

  return {
    answer: result.text,
    relevantChunks: capture.relevantChunks,
  };
}
