# Backend changes: voice chat + AI feedback (for Spoki AI Flutter client)

Use this as the implementation brief for your Node/other server that already handles Socket.IO `sendMessage` and `aifeedback`.

## 1. Voice upload (HTTP, not Socket)

- **Method / path:** `POST /api/v1/chat/voice-upload` (must match Flutter `BASEURL` + `chat/voice-upload`).
- **Auth:** Same Bearer / token mechanism as other `/api/v1/*` routes (Flutter sends the user token via existing `TokenInterceptor`).
- **Body:** `multipart/form-data` with one file field named **`audio`** (e.g. AAC/M4A from the app).
- **Response JSON** (200): at least one of:
  - `url` **or** `audioUrl` **or** `secureUrl` — **HTTPS** URL the app can `GET` to stream/play the file (signed S3/CDN URL is fine).
  - `transcription` **or** `text` **or** `message` — **full transcript** of what the learner said (this text is shown in the chat bubble as a normal message; there is **no** in-app audio player UI).

If upload fails, return 4xx/5xx with a JSON `message` when possible.

## 2. Socket `sendMessage` — text vs voice

The client sends:

**Text only (unchanged):**

```json
{ "message": "Hello there" }
```

**After voice upload:**

```json
{
  "message": "<transcript text>",
  "audioUrl": "<https://...>",
  "clientMessageId": "<opaque id from client>"
}
```

**Server should:**

- Persist message + `audioUrl` as needed.
- Broadcast to the room/session the same shape so other clients (or the same client) can render one row: **show `message` as the bubble text**, attach `audioUrl` for server-side logic only if you need it.
- **Echo / fan-out:** When broadcasting the user’s voice message back, **include the same `clientMessageId`** so the sender can deduplicate (the Flutter client skips adding a second row if it already has that id).

## 3. Socket `aifeedback` — pronunciation only with audio

The client emits:

```json
{
  "text": "<learner sentence>",
  "message": "<same>",
  "content": "<same>",
  "audioUrl": "<optional; present only for voice messages>",
  "hasAudio": true,
  "pronunciationRequested": true,
  "pronunciationMode": "audio"
}
```

For typed messages (no recording), client sends:

```json
{
  "text": "<typed sentence>",
  "message": "<same>",
  "content": "<same>",
  "hasAudio": false,
  "pronunciationRequested": false,
  "pronunciationMode": "disabled_without_audio"
}
```

**Rules:**

- **Grammar + vocabulary:** Use `text` / `message` / `content` as today.
- **Pronunciation block:** Run **only** when all are true:
  - `hasAudio === true`
  - `pronunciationRequested === true`
  - `audioUrl` is present and non-empty  
  Then download/reference `audioUrl`, run pronunciation model/ASR alignment, and return `pronunciation` in the `type: "ai"` payload.
- If any of the above is false (typed message), **must not** run pronunciation and **must omit** `pronunciation` in response.

Do **not** require “save” or bookmark actions in the payload; the app removed save icons.

## 4. AI feedback `type: "ai"` — full corrected sentence last

Extend the successful feedback object with **one** of:

- `fullCorrectedSentence` (preferred), or  
- `fullSentence`

Value: the **entire** corrected English sentence as a single string (the complete “right” version of what the learner said). The app shows this in a **dedicated card at the end** of the feedback stack, after grammar / pronunciation (if any) / vocabulary.

Example shape:

```json
{
  "type": "ai",
  "grammar": { "original": "...", "errors": [], "corrected": "..." },
  "pronunciation": { "word": "...", "phonetic": "...", "score": 72, "status": "..." },
  "vocabulary": { "suggestions": [] },
  "fullCorrectedSentence": "The complete corrected sentence goes here."
}
```

## 5. Security

- Serve audio from **HTTPS** URLs with **short-lived** signed URLs if using object storage.
- Validate MIME/size on upload; reject executable content.

## 6. Typing / errors

Keep existing `typing` and `type: "error"` behaviour for `aifeedback` so the Flutter loading and error states still work.

---

**Summary for the team:** Add `POST .../chat/voice-upload`, extend `sendMessage` with `audioUrl` + `clientMessageId`, extend `aifeedback` with optional `audioUrl` and conditional pronunciation, and add `fullCorrectedSentence` on the AI feedback response.
