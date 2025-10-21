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

## Real Example: Atlas Alchemy

```markdown
# Atlas Alchemy Constitution

## Core Principles

### Principle 1: 一時間コアループ
60分で達成感のあるゲームループ

### Principle 2: 探索が世界を拡張する
探索で新タイルが解放され、永続的に記録

### Principle 3: 血統戦略の深化
配合は戦略的な血統構築、世代ごとに強化

### Principle 4: 移動が都市を育てる
移動回数・距離・資源で都市が成長

### Principle 5: 戦利品が経済を回す
戦利品は経済シンクで使い切り、インフレ防止

## Non-Functional Requirements
- 60FPS minimum
- <16ms input latency
- <100ms save operation

## Scope
- In: 60分コアループ、4サブシステム
- Out: マルチプレイヤー、リアルタイム戦闘
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
    "ユーザシナリオとテスト": {
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
2. **Make testable**: "60-minute loop" > "fun gameplay"
3. **Reference in specs**: Link user stories to principles
4. **3-5 principles**: Not too many, not too few
