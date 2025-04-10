# Deep Linking with Privacy and Context in Mind

---

## Overview

- **Deep linking inside phase content** is **embedded as Markdown links**.
- **Tapping a link** **does not** jump to the middle of a thread.
- Instead, it **opens a translucent modal preview** of the linked content.
- **Deep linking to arbitrary thread positions is avoided** for privacy, context, and UX reasons.

---

## How it works

- Vector search results and citations **inject links** into Markdown.
- When tapped:
  - A **translucent modal overlay** appears with a **preview** of the content.
  - The user can **read the snippet** in context.
  - Optionally, the user can **navigate to the thread start** or **summary**, if access permits.
- **No direct linking** to arbitrary message indices in long threads.

---

## Privacy and Access

- Avoids exposing private or irrelevant parts of threads.
- Respects ownership and sharing permissions.
- Supports **gradual disclosure** of thread content.

---

## Future

- Use **thread contracts** and **reward systems** to manage:
  - Access control.
  - Sharing.
  - Linking granularity (e.g., summaries, highlights).

---

## Summary

- Deep links **show previews in modals**, not raw jumps.
- This respects privacy, improves UX, and prepares for future collaboration features.
