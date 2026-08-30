defmodule Mix.Tasks.Skills.Check do
  @shortdoc "Fails if .agents/skills does not mirror .claude/skills exactly"

  @moduledoc """
  Guards the skills mirror.

  Skills are authored once under `.claude/skills` (the canonical tree). Some agent
  harnesses read `.agents/skills` instead, so we expose the same content in both
  places via a symlink (`.agents/skills -> ../.claude/skills`).

  A symlink can be accidentally replaced by a real copy (e.g. by a tool that does not
  preserve symlinks, or a manual `cp`), after which the two trees drift apart and one
  harness silently reads stale guidance. This task is wired into `mix precommit` so
  that drift fails the build instead of shipping quietly.

  It treats `.claude/skills` as canonical, resolves a one-level symlink on either
  root so it compares the real directories, reads every regular file under both into
  a relative-path => contents map, and raises on any file missing from the mirror,
  extra in the mirror, or differing in content.
  """

  use Mix.Task

  @canonical ".claude/skills"
  @mirror ".agents/skills"
  @restore_cmd "rm -rf .agents/skills && ln -s ../.claude/skills .agents/skills"

  @impl Mix.Task
  def run(_args) do
    canonical_files = read_canonical!()
    mirror_files = read_mirror()

    case diff(canonical_files, mirror_files) do
      {[], [], []} ->
        Mix.shell().info(
          "skills.check: #{map_size(canonical_files)} files in sync " <>
            "(#{@canonical} <-> #{@mirror})."
        )

      {missing, extra, differing} ->
        report(missing, extra, differing)

        Mix.raise(
          "#{@mirror} is out of sync with #{@canonical}. " <>
            "Restore the symlink so the mirror always tracks canonical:\n\n    #{@restore_cmd}\n"
        )
    end
  end

  defp read_canonical! do
    root = resolve(@canonical)

    unless File.dir?(root) do
      Mix.raise(
        "#{@canonical} is missing (resolved to #{root}). " <>
          "Skills must be authored there; nothing to mirror."
      )
    end

    files = read_tree(root)

    if map_size(files) == 0 do
      Mix.raise("#{@canonical} is empty; there are no skills to mirror.")
    end

    files
  end

  defp read_mirror do
    root = resolve(@mirror)
    if File.dir?(root), do: read_tree(root), else: %{}
  end

  # Returns {missing_from_mirror, extra_in_mirror, differing_content}.
  defp diff(canonical_files, mirror_files) do
    missing = for {path, _} <- canonical_files, not Map.has_key?(mirror_files, path), do: path
    extra = for {path, _} <- mirror_files, not Map.has_key?(canonical_files, path), do: path

    differing =
      for {path, contents} <- canonical_files,
          Map.has_key?(mirror_files, path),
          Map.fetch!(mirror_files, path) != contents,
          do: path

    {missing, extra, differing}
  end

  # Resolve a one-level symlink to the real directory it points at; otherwise expand
  # the path as-is. This makes the comparison work whether a root is the real
  # directory or a symlink to it.
  defp resolve(path) do
    case File.read_link(path) do
      {:ok, target} -> Path.expand(target, Path.dirname(path))
      {:error, _} -> Path.expand(path)
    end
  end

  # Every regular file under `root`, as a map of path-relative-to-root => contents.
  defp read_tree(root) do
    root
    |> Path.join("**")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
    |> Map.new(fn file -> {Path.relative_to(file, root), File.read!(file)} end)
  end

  defp report(missing, extra, differing) do
    shell = Mix.shell()
    print_group(shell, "Missing from #{@mirror}", missing)
    print_group(shell, "Extra in #{@mirror} (not in #{@canonical})", extra)
    print_group(shell, "Differing content", differing)
  end

  defp print_group(_shell, _label, []), do: :ok

  defp print_group(shell, label, paths) do
    shell.error("#{label}:")
    Enum.each(Enum.sort(paths), fn path -> shell.error("  - #{path}") end)
  end
end
