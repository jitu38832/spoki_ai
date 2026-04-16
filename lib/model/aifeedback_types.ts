/**
 * Socket.IO contract: client emits `aifeedback`, listens `aifeedback` + `typing`.
 * Pronunciation score is indicative only (not real speech analysis).
 */

/** Optional audioUrl: when present, server should run pronunciation from audio only. */
export type AiFeedbackEmit =
  | {
      text: string;
      audioUrl?: string;
      hasAudio?: boolean;
      pronunciationRequested?: boolean;
      pronunciationMode?: 'audio' | 'disabled_without_audio';
    }
  | {
      message: string;
      audioUrl?: string;
      hasAudio?: boolean;
      pronunciationRequested?: boolean;
      pronunciationMode?: 'audio' | 'disabled_without_audio';
    }
  | {
      content: string;
      audioUrl?: string;
      hasAudio?: boolean;
      pronunciationRequested?: boolean;
      pronunciationMode?: 'audio' | 'disabled_without_audio';
    };

export type AiFeedbackTyping = {
  type: 'typing';
  status?: string;
  timestamp?: string;
};

export type AiFeedbackUserEcho = {
  type: 'user';
  text: string;
  timestamp?: string;
};

export type AiFeedbackError = {
  type: 'error';
  message: string;
  timestamp?: string;
};

export type GrammarBlock = {
  original: string;
  errors: string[];
  corrected: string;
};

export type PronunciationBlock = {
  word: string;
  phonetic: string;
  /** 0–100, indicative only */
  score: number;
  status: string;
};

export type VocabularySuggestion = {
  original: string;
  improvement: string;
};

export type VocabularyBlock = {
  suggestions: VocabularySuggestion[];
};

export type AiFeedbackAi = {
  type: 'ai';
  grammar?: GrammarBlock;
  pronunciation?: PronunciationBlock;
  vocabulary?: VocabularyBlock;
  /** Full grammatically correct sentence as one string (show last in UI). */
  fullCorrectedSentence?: string;
  fullSentence?: string;
  timestamp?: string;
};

/** Payload on `typing` when feedback is being generated */
export type TypingAiFeedbackScope = {
  type: 'aifeedback';
  status?: string;
};
