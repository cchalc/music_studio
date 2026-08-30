defmodule MusicStudio.Repo do
  use Ecto.Repo,
    otp_app: :music_studio,
    adapter: Ecto.Adapters.Postgres
end
