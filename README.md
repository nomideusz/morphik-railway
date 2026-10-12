# Deploy and Host Morphik on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/morphik-rag?referralCode=sLjDXb&utm_medium=integration&utm_source=button&utm_campaign=morphik-rag)

[Morphik](https://www.morphik.ai/) is an open-source RAG backend for documents: upload PDFs, Word, Excel and PowerPoint files, images and plain text, and Morphik parses, chunks and embeds them, then lets you search them and ask questions over them through a REST API or its Python and TypeScript SDKs, with metadata filters, folders and per-user scoping. This template runs the Morphik API and its ingestion worker with Postgres (pgvector), Redis and a Railway bucket for the files, and works with OpenAI, Anthropic, OpenRouter or any OpenAI-compatible endpoint through LiteLLM.

## About Hosting Morphik

The stack is four services and a bucket: Morphik (the API), Morphik Worker, Postgres, Redis and the Storage bucket.

- **Upstream's own image, pinned.** Both Morphik services build a thin wrapper around the official `ghcr.io/morphik-org/morphik-core` image at a fixed build (Morphik publishes no release tags, so the template pins an exact commit build instead of the moving `latest`). The wrapper only adds a Railway entrypoint and a `morphik.toml`; upgrading means bumping one `FROM` line.
- **Configured from variables.** Morphik reads its settings from `morphik.toml`. The entrypoint fills that file from the service variables on every boot, so models, keys and connection strings are all ordinary Railway variables.
- **API and worker scale separately.** Uploads go to the API, which stores the file and queues a job in Redis; the worker parses, chunks and embeds it. Because the two run in separate containers they share files through the Railway bucket, not a disk.
- **Secrets generated for you.** `JWT_SECRET_KEY`, `SESSION_SECRET_KEY` (upstream falls back to a publicly known default) and `ADMIN_SERVICE_SECRET` are generated at deploy time. Authentication is on: every API call needs a token.
- **Postgres with pgvector** stores documents, chunks and embeddings. Redis (the job queue) keeps an append-only file on its own volume.

## Common Use Cases

- A private "chat with your documents" backend for an internal tool or customer-facing app
- Semantic search across contracts, manuals, research papers or support docs, filtered by metadata
- A retrieval layer for AI agents that need grounded answers with sources
- Turning a pile of PDFs and slide decks into a queryable knowledge base through one API

## Dependencies for Morphik Hosting

- Postgres 17 with pgvector (included, private network only)
- Redis 8 (included, private network only)
- A Railway bucket for uploaded files (included)
- An API key for a model provider (OpenAI by default)

### Deployment Dependencies

- [Morphik documentation](https://www.morphik.ai/docs)
- [Morphik on GitHub](https://github.com/morphik-org/morphik-core)
- [Template source on GitHub](https://github.com/nomideusz/morphik-railway)

### Implementation Details

**Add a model key.** The defaults are `gpt-4.1-mini` for answers and `text-embedding-3-small` for embeddings, so fill in `OPENAI_API_KEY` on the Morphik service (the worker reads it from there). To use other models, set `MORPHIK_COMPLETION_MODEL` to any [LiteLLM](https://docs.litellm.ai/docs/providers) model name, such as `anthropic/claude-sonnet-4-5` with `ANTHROPIC_API_KEY` or `openrouter/google/gemini-2.5-flash` with `OPENROUTER_API_KEY`. Anthropic has no embedding models, so embeddings still need OpenAI or an OpenAI-compatible endpoint (`OPENAI_API_BASE`). **Choose the embedding model before ingesting anything.** The vector size (`MORPHIK_EMBEDDING_DIMENSIONS`) is fixed when the first document is stored.

**Get an API token.** Every request needs a bearer token. Create an app with the generated admin secret (copy `ADMIN_SERVICE_SECRET` from the Morphik service's Variables tab):

```bash
curl -X POST https://<your-domain>/cloud/generate_uri \
  -H "X-Morphik-Admin-Secret: <ADMIN_SERVICE_SECRET>" \
  -H "Content-Type: application/json" \
  -d '{"name": "my-app", "user_id": "admin"}'
```

The response holds a URI like `morphik://my-app:<token>@<your-domain>`. Pass the whole URI to the SDK (`Morphik("morphik://...")` in Python), or send `Authorization: Bearer <token>` to the REST API. Interactive API docs are at `/docs`. Each app gets its own token; to revoke one, use `POST /apps/rotate_token`. Rotating `JWT_SECRET_KEY` revokes every token at once.

**Try it.**

```bash
curl -X POST https://<your-domain>/ingest/file -H "Authorization: Bearer <token>" -F file=@report.pdf
curl -X POST https://<your-domain>/query -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" -d '{"query": "What is the budget?"}'
```

Ingestion runs in the background; `GET /documents/<id>/status` shows when a document is `completed`.

**What is turned off, and why.** ColPali (Morphik's page-image embeddings) and the reranker run large local vision and BGE models that need a GPU, so both are off; text retrieval over parsed documents works without them. After each deploy, the first PDF the worker parses downloads its OCR models (about 40 MB), so that document takes a little longer. Morphik's web UI is not included: it is under Morphik's Enterprise license, not the MIT license of the API.

**Redis has no password.** Morphik's API connects to Redis by host and port only, with no way to pass a password, so Redis runs without one. It has no public domain or TCP proxy and is reachable only on your project's private network; don't add a public endpoint to it.

**Custom domain.** After adding one, set `MORPHIK_API_DOMAIN` to it so newly generated URIs point at it.

**Resources.** Morphik's image is large (about 10 GB, it bundles PyTorch and document parsers), so it needs the Hobby plan or above: Trial and Free plans cap images at 4 GB, and the first build takes several minutes. In testing the API idled at about 0.9 GB of RAM and the worker at about 1.2 GB, rising to about 2 GB while parsing PDFs; with Postgres and Redis the stack idles at roughly 2.2 GB.

## Why Deploy Morphik on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Morphik on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
