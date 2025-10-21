# Spec-Kit Archive Scripts

Constitution準拠のインテリジェントspec管理スクリプト集。

## 概要

本ディレクトリには、Spec-Kitワークフローで完了したフィーチャーをアーカイブし、`specs/latest/`へインテリジェントにマージするスクリプトが含まれています。

### 主な機能

- **Constitution準拠マージ**: 憲章の5原則に基づいて、セクションごとに最適なマージ戦略を自動選択
- **累積的統合**: ユーザーストーリー、要件、フェーズなどを情報損失なく統合
- **汎用的対応**: spec.md、plan.md、tasks.md、data-model.mdなど複数ファイルタイプに対応

## スクリプト

### 1. `validate-implementation.sh`

仕様書が実装と整合しているかを検証します。

**使い方**:

```bash
.specify/scripts/bash/validate-implementation.sh --feature 002-my-feature
```

**チェック項目**:
- **spec.md**: P1ユーザーストーリーに対応するテストファイルの存在
- **plan.md**: 言及されている`src/`ファイルの実在性
- **data-model.md**: エンティティ定義がコード内に存在するか

**オプション**:
- `--feature <dir>`: 検証対象のフィーチャーディレクトリ名（必須）
- `--json`: JSON形式で結果を出力
- `--help`, `-h`: ヘルプを表示

### 2. `archive-feature.sh`

完了したフィーチャーを`specs/archive/`に移動し、`specs/latest/`へマージします。

**使い方**:

```bash
# 基本的な使い方
.specify/scripts/bash/archive-feature.sh --feature 002-specify-scripts-bash

# JSON出力モード（CI/CD向け）
.specify/scripts/bash/archive-feature.sh --json --feature 002-specify-scripts-bash
```

**オプション**:
- `--feature <dir>`: アーカイブ対象のフィーチャーディレクトリ名（必須）
- `--json`: JSON形式で結果を出力
- `--help`, `-h`: ヘルプを表示

**動作**:
1. **実装検証** (`.specify/scripts/bash/validate-implementation.sh`):
   - spec.mdのユーザーストーリーに対応するテストの存在確認
   - plan.mdで言及されたファイルの存在確認
   - data-model.mdのエンティティがコードに存在するか確認
   - 警告は情報提供のみ、アーカイブをブロックしない
2. `specs/<feature>/`から以下のファイルを処理:
   - `spec.md`, `plan.md`, `data-model.md`, `quickstart.md`, `research.md`
   - **注**: `tasks.md`は除外（完了済みタスクのため）
3. 既存の`specs/latest/`ファイルとインテリジェントマージ
4. `contracts/`ディレクトリを同期
5. フィーチャーディレクトリを`specs/archive/`へ移動

### 3. `merge-spec.sh`

Markdownファイルをセクション単位でインテリジェントにマージします。

**使い方**:

```bash
.specify/scripts/bash/merge-spec.sh \
  --base specs/latest/spec.md \
  --incoming specs/002-feature/spec.md \
  --output specs/latest/spec.md
```

**オプション**:
- `--base <file>`: ベースとなる既存ファイル（必須）
- `--incoming <file>`: マージする新規ファイル（必須）
- `--output <file>`: 出力先ファイル（必須）
- `--constitution <file>`: constitution.mdのパス（任意、原則検証用）
- `--help`, `-h`: ヘルプを表示

### 4. `parse-markdown-sections.awk`

Markdownをセクション単位でパースするAWKスクリプト（内部使用）。

### 5. `merge-rules.json`

マージ戦略の定義ファイル。Constitution原則に基づいたセクション別マージルール。

## マージ戦略

### spec.md

| セクション | 戦略 | 理由 |
|---|---|---|
| ユーザーストーリー | accumulate | 各ストーリーは独立価値があり累積 |
| 要件 (FR/NFR) | merge_by_id | ID単位で管理、最新を優先 |
| 成功指標 (SC) | accumulate_unique | 複数角度で測定するため累積 |
| エッジケース | accumulate | 例外処理の網羅性を高める |

### plan.md

| セクション | 戦略 | 理由 |
|---|---|---|
| サマリ | latest | 最新機能の概要を優先 |
| 技術コンテキスト | accumulate | 技術スタックの履歴を保持 |
| 憲章チェック | accumulate | 各フェーズの憲章準拠を累積 |
| リスクと対応 | accumulate | リスクの網羅性を高める |

### tasks.md

| セクション | 戦略 | 理由 |
|---|---|---|
| フェーズN: ... | accumulate | すべてのフェーズタスクを累積 |
| 依存関係と実行順序 | accumulate | 全体の制約を把握 |
| 実行方針 | latest | 最新の実行戦略を優先 |

### data-model.md

| セクション | 戦略 | 理由 |
|---|---|---|
| EntityName | merge_entities | エンティティ定義を統合 |

## ワークフロー例

### 1. フィーチャー開発完了後

```bash
# 現在のブランチを確認
git branch

# specs/002-my-feature/ が完了していることを確認
# → spec.md、plan.md、tasks.md が揃っている

# アーカイブ実行
.specify/scripts/bash/archive-feature.sh --feature 002-my-feature

# 結果確認
ls -la specs/archive/002-my-feature/  # アーカイブ済み
cat specs/latest/spec.md               # マージ済み
```

### 2. マージ結果の検証

```bash
# ユーザーストーリー数を確認（累積されているはず）
grep -c "^### ユーザーストーリー" specs/latest/spec.md

# 要件IDを確認（ID単位でマージされているはず）
grep "^- \*\*FR-" specs/latest/spec.md

# フェーズを確認（すべて累積されているはず）
grep "^## フェーズ" specs/latest/tasks.md
```

### 3. git commit

```bash
# 変更をステージング
git add specs/archive/ specs/latest/

# コミット
git commit -m "feat: archive 002-my-feature and merge to latest

- Archived specs/002-my-feature/ to specs/archive/
- Merged spec.md, plan.md, tasks.md, data-model.md to specs/latest/
- User stories: +4 (total: 8)
- Requirements: +7 (total: 16)
- Phases: +7 (total: 14)
"
```

## カスタマイズ

### マージルールの追加

`merge-rules.json`を編集して、新しいセクションタイプのマージ戦略を追加できます：

```json
{
  "rules": {
    "新しいセクション名": {
      "strategy": "accumulate",
      "reason": "累積理由の説明"
    }
  }
}
```

利用可能な戦略：
- `accumulate`: 両方の内容を累積
- `merge_by_id`: ID（FR-001など）単位でマージ
- `accumulate_unique`: 重複を除いて累積
- `merge_entities`: エンティティとしてマージ
- `latest`: 最新（incoming）を優先
- `latest_with_context`: 最新を優先しつつ、baseの重要情報を保持

### パターンマッチング

特定のパターンに一致するセクション名は自動的に戦略が割り当てられます：

- `^フェーズ[0-9]+:` → `accumulate` (tasks.md)
- `^[A-Z][a-zA-Z]+$` → `merge_entities` (data-model.md)

## トラブルシューティング

### Q: マージ結果が期待と異なる

**A**: 以下を確認してください：

1. `merge-rules.json`の戦略定義
2. セクション名の正確な一致（日本語の全角/半角、空白など）
3. `/tmp/test-merged-*.md`でドライランテスト

```bash
# ドライランテスト
.specify/scripts/bash/merge-spec.sh \
  --base specs/latest/spec.md \
  --incoming specs/002-feature/spec.md \
  --output /tmp/test-spec.md

# 結果を確認
diff -u specs/latest/spec.md /tmp/test-spec.md
```

### Q: 特定のセクションが消えた

**A**: セクション名が完全一致していない可能性があります。

```bash
# セクション名を確認
grep "^##" specs/latest/spec.md
grep "^##" specs/002-feature/spec.md
```

### Q: エンティティが重複している

**A**: data-model.mdのエンティティ名が大文字始まりの英単語になっているか確認してください。

## テスト

```bash
# 全ファイルタイプのマージテスト
for file in spec plan tasks data-model; do
  echo "=== Testing $file.md ==="
  .specify/scripts/bash/merge-spec.sh \
    --base specs/archive/001-core/$file.md \
    --incoming specs/002-feature/$file.md \
    --output /tmp/test-$file.md
  echo "Lines: $(wc -l < /tmp/test-$file.md)"
done
```

## 参考資料

- [Spec-Kit公式](https://github.com/context7-labs/spec-kit)
- [Atlas Alchemy Constitution](../../memory/constitution.md)
- [Spec-Kit Game Bestpractice](../../../docs/Spec-Kit-Game-Bestpractice.md)

