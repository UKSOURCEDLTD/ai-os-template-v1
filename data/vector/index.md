# Vector Index

Configuration and manifest for the semantic data store.
Used to enable retrieval-augmented generation (RAG) — finding relevant context without reading every file.

---

## Purpose

When the AI OS needs to answer questions like:
- "Have we written a proposal for a client like this before?"
- "What have we learned when [metric] drops?"
- "What did we try for [client] that didn't work?"

...it queries the vector store instead of scanning all files manually.

---

## Status

**Current:** Not yet implemented. Files are retrieved manually per session.
**Target:** Embed key documents and query via vector search.

---

## Planned embeddings

| Content | Source | Priority |
|---------|--------|----------|
| All past proposals | `data/historical/` | High |
| Client profiles | `clients/*/profile.md` | High |
| Strategy documents | `clients/*/` | High |
| Email threads (leads/clients) | Gmail | Medium |
| Monthly performance reports | `data/historical/` | Medium |
| Learnings | `memory/learnings.md` | Medium |
| Business context | `context/business.md` | Low (always loaded) |

---

## Implementation options

- **Local:** ChromaDB or LanceDB (file-based, no server needed)
- **Hosted:** Pinecone, Weaviate, or Supabase pgvector
- **Via Claude:** Use Claude's extended context window as a proxy until volume justifies a dedicated store

---

## When to implement

Trigger this when:
- Historical data folder contains 20+ documents, OR
- Manual file retrieval is slowing down responses, OR
- You need cross-client pattern matching at scale
