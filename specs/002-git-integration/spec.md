# Feature: Git Branch Integration

## User Stories

### US-003: Automated Branch Merge
**As a** developer following git-flow workflow  
**I want to** automatically merge archived changes into parent branch  
**So that** I don't have to manually switch branches and merge after archiving

**Acceptance Criteria**:
- System detects if current branch is a spec feature branch
- Parent branch is automatically identified (main/master/develop)
- User is prompted to merge after successful archive
- Merge uses `--no-ff` to preserve feature history
- Optional branch cleanup after merge

**Priority**: P2

### US-004: Safe Merge Operations
**As a** developer with uncommitted changes  
**I want** the system to prevent merge if I have uncommitted work  
**So that** I don't lose work-in-progress

**Acceptance Criteria**:
- System checks for uncommitted changes before merge
- Clear error message if uncommitted changes exist
- Suggests stashing or committing before retry
- Never performs destructive operations without confirmation

**Priority**: P1

## Functional Requirements

### FR-004: Branch Detection
The system shall detect if current branch matches spec feature branch pattern (`feat/specs-NNN-*`).

### FR-005: Parent Branch Identification
The system shall identify parent branch by:
1. Using git show-branch analysis
2. Falling back to common branch names (main, master, develop)
3. Prompting user if detection fails

### FR-006: Interactive Merge
The system shall prompt user before merge:
- Display detected parent branch
- Ask for merge confirmation (y/N)
- Perform merge only on explicit confirmation
- Offer branch deletion after successful merge

### FR-007: --with-merge Flag
The system shall provide a `--with-merge` flag for archive-feature.sh that enables git integration.

## Non-Functional Requirements

### NFR-004: Git Compatibility
The system shall work with Git 2.0+ without requiring advanced Git features.

### NFR-005: Error Recovery
On merge failure, the system shall return to original branch and preserve all changes.

## Success Criteria

### SC-004: Workflow Efficiency
Archiving and merging a feature takes one command instead of five separate git commands.

### SC-005: Safety
Zero data loss incidents due to merge operations in production usage.

## Dependencies
- Git 2.0+
- Core archive functionality (FR-001, FR-002)

## Risks
- **Merge conflicts**: If parent branch has conflicting changes
  - *Mitigation*: Detect conflicts, abort merge, suggest manual resolution
- **Wrong parent detection**: System merges into incorrect branch
  - *Mitigation*: Always show detected branch, require confirmation

