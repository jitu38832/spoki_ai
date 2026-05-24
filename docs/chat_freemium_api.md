# Chat freemium API (backend contract)

The Node implementation that matches these routes lives in **`spoki_ai_backend/`** (listed in `.gitignore` in the Flutter repo so the API stays a separate checkout; reference: `src/services/chatFreemium.service.js` and routes in `src/routes/user/user.routes.js`).

Flutter syncs quotas from your API so **translate / Improve Sentence / in-chat AI voice** limits follow the logged-in account and are **not reset** by clearing local preferences on logout/login.

**Premium for chat metering** comes only from **`data.premium`** on this endpoint after the client successfully syncs quotas (not from the IAP flag alone). The store receipt must be acknowledged by **`subscriptions/iap/register`** so the backend links the subscription to the logged-in user; see `SubscriptionService`, `syncBillingAndChatQuotasAfterLogin`, and `post_login_entitlements_sync.dart`.

Base URL matches `BASEURL` in `lib/view/utils/constants.dart`.

All routes require **`Authorization: Bearer <user_jwt>`** (same token as other `users/me` calls).

---

## `GET users/me/chat-freemium`

Returns the current metering snapshot.

**Suggested response (`200`):**

```json
{
  "success": true,
  "data": {
    "premium": false,
    "limits": {
      "translate": 2,
      "improve_sentence": 2,
      "voice_tts": 2
    },
    "used": {
      "translate": 0,
      "improve_sentence": 0,
      "voice_tts": 0
    }
  }
}
```

- If `premium` is `true`, the client treats the user as fully unlocked for these chat features (IAP/register flow may mirror this flag).
- `limits.*` defaults to **`2`** in the app when omitted.
- Keys may also use camelCase in JSON; see `ChatFreemiumQuota.fromBackendJson`.

---

## `POST users/me/chat-freemium/consume`

Atomically consumes **one** use of a gated feature **if** the user is allowed (not premium over limit).

**Body (`application/json`):**

```json
{ "feature": "translate" }
```

`feature` must be one of:

| Value | Meaning |
|--------|---------|
| `translate` | In-chat Translate action |
| `improve_sentence` | Improve Sentence (metered on Socket.IO `aifeedback` when connected — see below) |
| `voice_tts` | **Chat Voice Settings**: each commit to a persona different from the current effective Inworld chat voice counts once (playback does not consume) |

**Suggested success (`200`)** — explicit allowance recommended:

```json
{
  "success": true,
  "allowed": true,
  "data": {
    "premium": false,
    "limits": { "translate": 2, "improve_sentence": 2, "voice_tts": 2 },
    "used": { "translate": 1, "improve_sentence": 0, "voice_tts": 0 }
  }
}
```

**Quota exhausted** — use **`403`** or **`200`** with **`"allowed": false`** and an optional **`message`** for the UI.

Premium users: return **`allowed": true`** without incrementing counters (optional but keeps clients simple).

---

## Improve Sentence — Socket.IO `aifeedback`

Improve Sentence is executed on the websocket handler **`aifeedback`** in **`spoki_ai_backend/src/services/chat.service.js`**.

For bypass resistance:

1. The client attaches the same JWT as REST: **`token`**, **`accessToken`**, or **`authorization`** (`Bearer <jwt>`).
2. The server verifies JWT → `userId`, then calls **`chatFreemiumService.consume(userId, "improve_sentence")`** once per successful request **before** running the AI model.

On failure (`403`-equivalent quota or missing/invalid JWT), emit **`aifeedback`** with **`type: "error"`** and a **`message`**; the Flutter app reloads quotas from **`GET users/me/chat-freemium`**.

REST **`POST …/consume`** with `feature: "improve_sentence"` remains available for diagnostics or offline paths; connected chat does **not** pre-consume that route (the socket call is authoritative to avoid double-charging).

---

## Until the backend ships

If `GET users/me/chat-freemium` fails (network, 404), the app falls back to **local counters** (`chat_freemium_*` keys). That restores the legacy **reset-on-logout** behaviour only in that degraded mode.
