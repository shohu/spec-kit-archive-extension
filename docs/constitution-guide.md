# Constitution Setup

## What Is It?

`constitution.md` defines your project's immutable principles. The archive system uses it to determine merge strategies.

## Location

```bash
.specify/memory/constitution.md
```

## Basic Structure

```markdown
# Project Name Constitution

## Core Principles

### Principle 1: [Name]
Description of unchanging value

### Principle 2: [Name]
Description of unchanging value

## Non-Functional Requirements
- Performance targets
- Quality standards

## Scope
- In: What we do
- Out: What we don't do
```

## Real Example: Web Application

```markdown
# My Web App Constitution

## Core Principles

### Principle 1: User Privacy First
All user data is encrypted at rest and in transit

### Principle 2: Progressive Enhancement
Core functionality works without JavaScript

### Principle 3: Accessibility by Default
WCAG 2.1 AA compliance minimum for all features

### Principle 4: API-First Design
Every UI feature has a corresponding API endpoint

### Principle 5: Data Integrity
All mutations are transactional and auditable

## Non-Functional Requirements
- 99.9% uptime SLA
- <200ms API response time (p95)
- <3s initial page load
- WCAG 2.1 AA compliance

## Scope
- In: REST API, web UI, authentication, data management
- Out: Mobile apps, real-time collaboration, AI features
```

## How It Affects Merging

- **Additive principles** (e.g., "Each feature adds value") → `accumulate` strategy
- **Refinement principles** (e.g., "Improve quality") → `merge_by_id` strategy
- **Unification principles** (e.g., "Consistent data model") → `merge_entities` strategy

## Customize Merge Rules

Edit `config/merge-rules.json` to align with your constitution:

```json
{
  "rules": {
    "User Stories and Tests": {
      "strategy": "accumulate",
      "reason": "Each story represents distinct value per principle"
    }
  },
  "constitution_principles": [
    "Your principle 1",
    "Your principle 2"
  ]
}
```

## Best Practices

1. **Keep stable**: Constitution changes rarely
2. **Make testable**: "<200ms response time" > "fast performance"
3. **Reference in specs**: Link user stories to principles
4. **3-5 principles**: Not too many, not too few
