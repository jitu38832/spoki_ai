# Story freemium API

Server: `spoki_ai_backend/src/services/storyFreemium.service.js`. Routes live next to chat freemium in `src/routes/user/user.routes.js`.

Flutter: `StoryFreemium` + `GET/POST users/me/story-freemium*`. Sync after login (`syncBillingAndChatQuotasAfterLogin`) and after billing (`SubscriptionService`).

All routes require **`Authorization: Bearer <jwt>`**.

---

## Story creation (`POST /story-writing`)

For **non‑premium** accounts the server applies:

| Rule | Detail |
|------|--------|
| Genres | **Free:** Adventure, Science fiction, Mystery, Drama, Historical (matching tolerates spelling/casing). Others → **403**. |
| Length | **Short** only on free tier; **Medium** / **Long** → **403**. |
| Short stories | **Unlimited** for non‑premium on allowed genres (no generation / fluent-level slot cap). |

`GET` still returns `story_generation` / `story_fluent_level` **limits** as a large display number (not enforced for short free-genre creates). **Quiz** remains capped at **2** distinct story unlocks. **Story listen-aloud (`story_tts`)** is capped at **2 playback starts per `playback_key`** (typically `story:<storyObjectId>`), not unlimited replays on the same story.

---

## `GET users/me/story-freemium`

Example **`200`**:

```json
{
  "success": true,
  "data": {
    "premium": false,
    "limits": {
      "story_generation": 1000000,
      "story_fluent_level": 1000000,
      "story_tts": 2,
      "story_quiz": 2
    },
    "used": {
      "story_generation": 0,
      "story_fluent_level": 0,
      "story_tts": 0,
      "story_quiz": 0
    }
  }
}
```

`used.story_quiz` is the count of **distinct** story Mongo IDs that have unlocked quiz access on the free tier.

`used.story_tts` is the **total** listen-aloud starts summed across playback keys (`limits.story_tts` stays **2** meaning **max starts per single key**, not global).

---

## `POST users/me/story-freemium/consume`

JSON body:

| `feature` | Required fields |
|-----------|-------------------|
| `story_quiz` | `story_id` (24-char hex ObjectId) |
| `story_tts` | `playback_key` (e.g. `story:<storyObjectId>`) |

**Quiz:** Same `story_id` revisits reuse the prior unlock and do **not** consume another of the **2** story slots.

**Listen aloud (`story_tts`):** Each consume increments the start count for that **`playback_key`**. Non‑premium users get **up to 2** successful consumes **per key** (same story = same key); further presses → **403** until Premium.

Integrated from **`quiz.service`** when exposing a **ready** quiz (HTTP `/quiz/...`, socket `storyQuizStatus`, and `POST quiz/generate` after persistence — failed metering rolls back newly created quiz documents).
