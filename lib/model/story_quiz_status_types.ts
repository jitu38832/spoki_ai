/**
 * Socket.IO story quiz readiness (same server as chat).
 * Client emits getStoryQuizStatus; server pushes storyQuizStatus.
 */

export type GetStoryQuizStatusEmit = {
  storyId: string;
  token: string;
  requestId?: string;
};

export type QuizGenerationStatus =
  | 'ready'
  | 'processing'
  | 'failed'
  | 'pending';

/** Same inner shape as GET /quiz/story/:storyId or quiz/generate `data` */
export type StoryQuizData = {
  id?: string;
  questions?: unknown[];
  metadata?: Record<string, unknown>;
  inputParams?: Record<string, unknown>;
  story?: Record<string, unknown>;
};

export type StoryQuizStatusData = {
  quizGenerationStatus: QuizGenerationStatus;
  quiz?: StoryQuizData;
  error?: string;
};

export type StoryQuizStatusResponse = {
  success: boolean;
  message?: string;
  data?: StoryQuizStatusData;
  timestamp?: string;
  requestId?: string;
};

export type TypingStoryQuiz = {
  type: 'storyQuiz';
  status?: string;
};
