import Config

# Local development secrets.
#
# Copy this file to `config/dev.secret.exs` and fill in real values:
#
#     cp config/dev.secret.example.exs config/dev.secret.exs
#
# `config/dev.secret.exs` is git-ignored and imported by `config/dev.exs` only if
# it exists, so the app boots fine without it. `.worktreeinclude` lists it so
# worktree tooling copies your filled-in secrets into each new worktree.
#
# Keep real secrets OUT of version control. Production secrets are read from
# environment variables in `config/runtime.exs`, not from this file.
#
# This project has no external service integrations yet — billing, transactional
# email, and analytics are planned for later phases. Add their keys here when those
# phases land, for example:
#
#     config :music_studio, :some_service, api_key: "dev-only-key"
