---
name: liveview-interactions
description: Deciding whether a UI interaction (a phx-click and friends) should be handled on the client with Phoenix.LiveView.JS commands or sent to the server via handle_event. Use when adding buttons, toggles, menus, tabs, modals, or any click/keydown/blur behavior and you must choose client vs server. Triggers on phx-click, phx-click-away, phx-window-keydown, Phoenix.LiveView.JS, JS.toggle, JS.show, JS.hide, JS.add_class, JS.remove_class, JS.dispatch, JS.push, JS.transition, handle_event, optimistic UI.
when_to_use: Use to decide where an interaction runs (client JS command vs server round-trip) before wiring it. To author the JS hook or push_event plumbing use phoenix-liveview; for the button/component markup and styling use ui-and-assets; for form submit/validate events use phoenix-foundations.
paths: lib/music_studio_web/**/*.heex, lib/music_studio_web/live/**/*.ex
---

# When a phx-click belongs on the client vs. the server

Every interaction is one of two kinds. Choosing the wrong one either wastes a
network round-trip on something the browser could do instantly, or hides state on
the client where it silently disappears on the next re-render.

## The decision

**Handle it on the client (`Phoenix.LiveView.JS` command) when the interaction only
changes presentation and nothing on the server needs to know about it.** These are
DOM/visual toggles: opening a menu, showing/hiding a panel, switching a purely
visual tab, dismissing a client-only banner, adding a CSS class, scrolling, focusing.
No data changes, no validation, no persistence, no other user is affected.

**Send it to the server (`phx-click="event"` → `handle_event/3`) when the
interaction changes application state.** Anything that reads or writes the database,
must be validated or authorized, needs to survive a reconnect or LiveView re-render,
must be visible to other connected clients, or feeds a subsequent server decision.

Litmus test: *"If the LiveView re-renders (a patch, another event, a reconnect),
must this change still be true?"* If yes → the state lives on the server, so the
event must go to the server. Client-only `JS` changes are **not** reflected in the
server's assigns and are lost on the next diff/patch.

## Client-side: `Phoenix.LiveView.JS`

`Phoenix.LiveView.JS` is aliased as `JS` in `music_studio_web.ex`, so use it directly
in templates. Commands run in the browser with no round-trip:

    <button phx-click={JS.toggle(to: "#menu")}>Menu</button>
    <div id="menu" class="hidden">…</div>

    <button phx-click={JS.hide(to: "#banner", transition: "fade-out")}>Dismiss</button>

    <button phx-click={JS.add_class("ring-2", to: "#card")}>Highlight</button>

Common commands: `JS.show/1`, `JS.hide/1`, `JS.toggle/1`, `JS.add_class/2`,
`JS.remove_class/2`, `JS.toggle_class/2`, `JS.transition/2`, `JS.dispatch/2`,
`JS.focus/1`, `JS.set_attribute/2`. Pair with `phx-click-away`,
`phx-window-keydown`, and `phx-key` for menus and dialogs (e.g. close on Escape or
outside click — still client-side).

## Server-side: `phx-click` + `handle_event/3`

    <button phx-click="delete" phx-value-id={task.id}>Delete</button>

    def handle_event("delete", %{"id" => id}, socket) do
      task = Tasks.get_task!(id)
      {:ok, _} = Tasks.delete_task(task)
      {:noreply, stream_delete(socket, :tasks, task)}
    end

State that drives the UI (a selected record, a persisted "expanded" flag, a count)
belongs in `assign`s and is changed only through `handle_event`, so it re-renders
correctly and survives reconnects.

## Combining both: `JS.push`

For optimistic UI, chain a client command with a server push in one attribute —
the DOM updates instantly *and* the server is notified:

    <button phx-click={JS.hide(to: "#todo-#{id}") |> JS.push("complete", value: %{id: id})}>
      Done
    </button>

`JS.push/2` still calls `handle_event/3`; use it when you want an immediate visual
effect ahead of the authoritative server update. If the server re-renders the item,
its assigns win — so keep the server as the source of truth.

## Rules of thumb

- Pure DOM/visual state, no data → `JS` command, client-side. Don't spend a round-trip on it.
- Touches data, validation, auth, persistence, other clients, or must survive re-render → server `handle_event`.
- Never reach for a colocated hook or external `phx-hook` for something a `JS` command already does — hooks are for behavior `JS` can't express (see phoenix-liveview).
- Never use inline `<script>` in HEEx for interactions; use `JS` commands or a colocated hook.
