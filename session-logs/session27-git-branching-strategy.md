# Session 27 - Git Branching Strategy

## What was done
- Created a real feature branch instead of committing directly to main
- Made a genuine change: documented the new branching strategy in README.md
- Pushed the feature branch and opened a real pull request on GitHub
- Set up branch protection on main: required a pull request before merging, and initially required 1 approving review
- Confirmed protection was genuinely enforced: the PR showed merging was blocked and the merge button was disabled
- Attempted to approve the PR as the repo owner, to test whether self-approval was possible
- Discovered a real, hard GitHub platform constraint: pull request authors cannot approve their own pull requests, and this cannot be changed by any repo setting
- Deliberately did not use the bypass-rules option, since normalizing bypassing a security control teaches the wrong instinct
- Fixed by unchecking required approvals while keeping the required pull request rule - a genuinely different and more limited fix than adding a second reviewer would be
- Merged the PR normally once unblocked, no bypass used
- Cleaned up both the local and remote feature branch after merging
- Tagged the merge as a real release point: v1.0-branching

## Why this matters
Working directly on main is like every contractor hammering nails into the same load-bearing wall simultaneously. A feature branch is a personal scaffold, only passing inspection through PR review makes it part of the real structure. For a solo maintainer, PR required but approval not required is the honest middle ground.

## Key finding - GitHub platform constraint, not a repo setting
Pull request authors cannot approve their own pull requests. This is enforced by GitHub itself and cannot be disabled through any branch protection configuration, distinct from repo-level rules which usually can be adjusted freely.

## Note
Reference verification: multiple sources disagreed on what Day 11 of the DevOps Zero to Hero series covers. Per the established standard, cited the general series with no specific day rather than guessing.
