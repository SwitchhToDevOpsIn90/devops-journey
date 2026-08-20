# Branch Protection Rule - Found Disabled, Fixed and Verified

## What was found
While reviewing recent commits, noticed a direct push to main succeeded without any PR, despite Session 27 having deliberately configured "Require a pull request before merging" on this exact branch. This should have been rejected.

## Investigation
Checked GitHub repo Settings -> Branches -> main rule directly. The rule still existed as a named entry ("main - Currently applies to 1 branch"), but every single checkbox inside it was unchecked, including "Require a pull request before merging." The rule had become an empty shell at some point after Session 27 - exact cause unknown, not something worth guessing at without evidence.

## Fix
Re-checked "Require a pull request before merging" on the main branch protection rule. Left "Require approvals" and all other options unchecked, matching the original Session 27 decision for a solo repo.

## Verification - tested the fix directly, not assumed
Attempted a real direct push to main from the Mac terminal after saving the fix. Result was genuinely informative:

git push origin main
remote: Bypassed rule violations for refs/heads/main:
remote: - Changes must be made through a pull request.

## Key finding - GitHub allows repo owners to bypass branch protection by default
The rule was confirmed active - GitHub explicitly detected and logged the violation. But because the push came from the repo owner, and "Do not allow bypassing the above settings" was left unchecked, GitHub allowed the push through anyway, logged as an explicit bypass rather than a silent pass. This is standard GitHub behavior, not a bug: repo admins can bypass branch protection rules unless that specific option is checked.

## Decision
Deliberately left bypass ability enabled for the repo owner, rather than checking "Do not allow bypassing the above settings." Reasoning: keeping an emergency bypass valve is standard real-world practice for solo-maintained repos, and fully locking out the owner is a stricter setting more appropriate for team repos with real trust boundaries. The discipline that actually matters going forward is choosing to use the PR workflow deliberately, not relying on the rule to physically prevent every direct push.

## Why this matters
A branch protection rule that exists as a named entry but has no checkboxes enabled provides zero actual protection, while looking correctly configured at a glance. Always verify a security control by testing it directly (attempting the action it should block), not just by confirming the rule's name still appears in settings.
