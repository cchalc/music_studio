---
name: phoenix-foundations
description: Ecto queries and changesets, router scoping/aliasing, HEEx template syntax, and form handling with to_form/<.form>/<.input> for this Phoenix app. Use when writing schemas, queries, migrations, routes, .heex templates, or forms. Triggers on scope, pipe_through, Ecto.Query, preload, Ecto.Changeset.get_field, validate_number, ecto.gen.migration, ~H, .heex, cond/case in templates, phx-no-curly-interpolation, class list [...] syntax, to_form, <.form>, <.input>, @form[:field].
when_to_use: Use for non-LiveView Phoenix building blocks (Ecto, router, HEEx, forms). For LiveView streams, JS hooks, push_event, or LiveView tests use phoenix-liveview; for layout/component/Tailwind conventions use ui-and-assets.
paths: lib/music_studio/**/*.ex, lib/music_studio_web/**/*.ex, lib/music_studio_web/**/*.heex, priv/repo/**/*.exs
---

# Phoenix foundations: Ecto, router, HEEx, forms

## Router

- Phoenix router `scope` blocks include an optional alias which is prefixed for all routes within the scope. **Always** be mindful of this when creating routes within a scope to avoid duplicate module prefixes.
- You **never** need to create your own `alias` for route definitions! The `scope` provides the alias:

      scope "/admin", MusicStudioWeb.Admin do
        pipe_through :browser

        live "/users", UserLive, :index
      end

  the `UserLive` route would point to the `MusicStudioWeb.Admin.UserLive` module.
- `Phoenix.View` no longer is needed or included with Phoenix, don't use it.

## Ecto

- **Always** preload Ecto associations in queries when they'll be accessed in templates, e.g. a message that needs to reference `message.user.email`.
- Remember `import Ecto.Query` and other supporting modules when you write `seeds.exs`.
- `Ecto.Schema` fields always use the `:string` type, even for `:text` columns, e.g. `field :name, :string`.
- `Ecto.Changeset.validate_number/2` **DOES NOT SUPPORT the `:allow_nil` option**. By default, Ecto validations only run if a change for the given field exists and the change value is not nil, so such an option is never needed.
- You **must** use `Ecto.Changeset.get_field(changeset, :field)` to access changeset fields.
- Fields which are set programmatically, such as `user_id`, must not be listed in `cast` calls or similar for security purposes. Instead they must be explicitly set when creating the struct.
- **Always** invoke `mix ecto.gen.migration migration_name_using_underscores` when generating migration files, so the correct timestamp and conventions are applied.

## HEEx templates

- Phoenix templates **always** use `~H` or `.html.heex` files (known as HEEx), **never** use `~E`.
- Elixir supports `if/else` but **does NOT support `if/else if` or `if/elsif`**. **Never use `else if` or `elseif` in Elixir**; **always** use `cond` or `case` for multiple conditionals.

  **Never do this (invalid)**:

      <%= if condition do %>
        ...
      <% else if other_condition %>
        ...
      <% end %>

  Instead **always** do this:

      <%= cond do %>
        <% condition -> %>
          ...
        <% condition2 -> %>
          ...
        <% true -> %>
          ...
      <% end %>

- HEEx requires special tag annotation if you want to insert literal curlies like `{` or `}`. To show a textual code snippet on the page in a `<pre>` or `<code>` block you *must* annotate the parent tag with `phx-no-curly-interpolation`:

      <code phx-no-curly-interpolation>
        let obj = {key: "val"}
      </code>

  Within `phx-no-curly-interpolation` annotated tags, you can use `{` and `}` without escaping them, and dynamic Elixir expressions can still be used with `<%= ... %>` syntax.

- HEEx class attrs support lists, but you must **always** use list `[...]` syntax. You can use the class list syntax to conditionally add classes; **always do this for multiple class values**:

      <a class={[
        "px-2 text-white",
        @some_flag && "py-5",
        if(@other_condition, do: "border-red-500", else: "border-blue-100"),
        ...
      ]}>Text</a>

  and **always** wrap `if`'s inside `{...}` expressions with parens, like done above (`if(@other_condition, do: "...", else: "...")`).

  and **never** do this, since it's invalid (note the missing `[` and `]`):

      <a class={
        "px-2 text-white",
        @some_flag && "py-5"
      }> ...
      => Raises compile syntax error on invalid HEEx attr syntax

- **Never** use `<% Enum.each %>` or non-for comprehensions for generating template content; instead **always** use `<%= for item <- @collection do %>`.
- HEEx HTML comments use `<%!-- comment --%>`. **Always** use the HEEx HTML comment syntax for template comments.
- HEEx allows interpolation via `{...}` and `<%= ... %>`, but `<%= %>` **only** works within tag bodies. **Always** use the `{...}` syntax for interpolation within tag attributes, and for interpolation of values within tag bodies. **Always** interpolate block constructs (if, cond, case, for) within tag bodies using `<%= ... %>`.

  **Always** do this:

      <div id={@id}>
        {@my_assign}
        <%= if @some_block_condition do %>
          {@another_assign}
        <% end %>
      </div>

  and **Never** do this – the program will terminate with a syntax error:

      <%!-- THIS IS INVALID NEVER EVER DO THIS --%>
      <div id="<%= @invalid_interpolation %>">
        {if @invalid_block_construct do}
        {end}
      </div>

## Forms

- **Always** use the imported `Phoenix.Component.form/1` and `Phoenix.Component.inputs_for/1` functions to build forms. **Never** use `Phoenix.HTML.form_for` or `Phoenix.HTML.inputs_for` as they are outdated.
- When building forms **always** use the already imported `Phoenix.Component.to_form/2` (`assign(socket, form: to_form(...))` and `<.form for={@form} id="msg-form">`), then access those forms in the template via `@form[:field]`.
- **Always** add unique DOM IDs to key elements (like forms, buttons, etc.) when writing templates; these IDs can later be used in tests (`<.form for={@form} id="product-form">`).
- For "app wide" template imports, you can import/alias into the `music_studio_web.ex`'s `html_helpers` block, so they will be available to all LiveViews, LiveComponents, and all modules that do `use MusicStudioWeb, :html`.

### Creating a form from params

If you want to create a form based on `handle_event` params:

    def handle_event("submitted", params, socket) do
      {:noreply, assign(socket, form: to_form(params))}
    end

When you pass a map to `to_form/1`, it assumes said map contains the form params, which are expected to have string keys. You can also specify a name to nest the params:

    def handle_event("submitted", %{"user" => user_params}, socket) do
      {:noreply, assign(socket, form: to_form(user_params, as: :user))}
    end

### Creating a form from changesets

When using changesets, the underlying data, form params, and errors are retrieved from it. The `:as` option is automatically computed too. E.g. if you have a user schema:

    defmodule MusicStudio.Users.User do
      use Ecto.Schema
      ...
    end

And then you create a changeset that you pass to `to_form`:

    %MusicStudio.Users.User{}
    |> Ecto.Changeset.change()
    |> to_form()

Once the form is submitted, the params will be available under `%{"user" => user_params}`. In the template, the form assign can be passed to the `<.form>` function component:

    <.form for={@form} id="todo-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:field]} type="text" />
    </.form>

Always give the form an explicit, unique DOM ID, like `id="todo-form"`.

### Avoiding form errors

**Always** use a form assigned via `to_form/2` in the LiveView, and the `<.input>` component in the template. In the template **always** access forms this way:

    <%!-- ALWAYS do this (valid) --%>
    <.form for={@form} id="my-form">
      <.input field={@form[:field]} type="text" />
    </.form>

And **never** do this:

    <%!-- NEVER do this (invalid) --%>
    <.form for={@changeset} id="my-form">
      <.input field={@changeset[:field]} type="text" />
    </.form>

- You are FORBIDDEN from accessing the changeset in the template as it will cause errors.
- **Never** use `<.form let={f} ...>` in the template; instead **always use `<.form for={@form} ...>`**, then drive all form references from the form assign as in `@form[:field]`. The UI should **always** be driven by a `to_form/2` assigned in the LiveView module that is derived from a changeset.
