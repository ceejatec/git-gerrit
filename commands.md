commands:

gerrit init - create gerrit remote

gerrit start <branchname> "local notes" [ <upstream> ] - create and check out new working branch tracking <upstream> with a change ID
  - error if branch already exists (perhaps -f to re-create; would this maintain any metadata? auto-abandon old stuff?)

gerrit update - fetch all tracking branches; rebase current (all?) working branches from upstream
  - if new commits include any known change IDs (change ID / branch tuple?), close corresponding working branches: no diffs, ask for confirmation, then delete working branch

gerrit push [ -q ] - squash local changes atop tracking branch, create commit message, push to Gerrit
  - if not changed since last submit, ask for confirmation
  - -q - don't bring up message in editor
  - if only one local commit, start with that commit message as-is
  - argument to specify topic

gerrit merge <upstream> - fetch <upstream>

gerrit abandon <branchname> - delete local branch and metadata; if change uploaded, Abandon it? With confirmation?

gerrit status - list working branches with notes; submit status; etc.


metadata to keep:

list of working branches, each with:
  - initial notes
  - change-ID
  - upstream branch
  - commit message
  - whether uploaded to Gerrit or not, and at what SHA
also remember a default branch - default to "main" or "master"

other things:

ability to specify change-id somewhere?
improve automatic commit message - if only one commit, use message as-is
don't require local branch that matches tracking branch
fix problem of "no such directory" when running "gerrit push" from a newly-added directory
allow for prompt to be updated with current working branch?