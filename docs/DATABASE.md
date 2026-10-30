# Database Schema — Offline Vault

> Human + AI readable schema. The **real** source of truth is the SQLite schema migrations in code.
> The mermaid diagram and the DBML block below describe the SAME tables, columns, and relationships.

**How to view it visually**
- Mermaid: open this file in Markdown preview (`Ctrl+Shift+V`) to view the rendered diagram.
- DBML: copy the dbml block into https://dbdiagram.io for an interactive diagram.

- **Database:** SQLite 3 (Offline on-device database)
- **Encryption:** AES-256-GCM encrypted payloads for sensitive fields (`username`, `password`, `notes`, `content`).
- **Naming:** tables plural snake_case, columns snake_case, PK `id`, timestamps `created_at`/`updated_at`.

## Diagram (mermaid)

```mermaid
erDiagram
  credentials {
    string id PK
    string title
    string username "encrypted"
    string password "encrypted"
    string url
    string category
    string notes "encrypted"
    int created_at
    int updated_at
  }

  notes {
    string id PK
    string title
    string content "encrypted"
    string category
    int is_pinned
    int created_at
    int updated_at
  }

  app_metadata {
    string key PK
    string value
    int updated_at
  }
```

## DBML

```dbml
Table credentials {
  id varchar [pk]
  title varchar [not null]
  username text [note: 'AES-256-GCM encrypted']
  password text [note: 'AES-256-GCM encrypted']
  url varchar
  category varchar [default: 'general']
  notes text [note: 'AES-256-GCM encrypted']
  created_at integer [not null]
  updated_at integer [not null]
}

Table notes {
  id varchar [pk]
  title varchar [not null]
  content text [note: 'AES-256-GCM encrypted']
  category varchar [default: 'general']
  is_pinned integer [default: 0]
  created_at integer [not null]
  updated_at integer [not null]
}

Table app_metadata {
  key varchar [pk]
  value text [not null]
  updated_at integer [not null]
}
```

