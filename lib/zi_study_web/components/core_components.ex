defmodule ZiStudyWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: ZiStudyWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders a responsive topbar with logo, navigation and actions.
  """
  attr :id, :string, default: "topbar"
  attr :class, :string, default: nil
  attr :show_on_scroll, :boolean, default: true
  attr :current_scope, :map, default: %{}
  attr :logout_path, :string, default: "/users/log-out"
  attr :login_path, :string, default: "/users/log-in"
  attr :register_path, :string, default: "/users/register"
  attr :sidebar_layout, :boolean, default: false

  slot :logo_src, required: true
  slot :logo_text
  slot :nav_links
  slot :mobile_links
  slot :actions
  slot :profile_links

  def topbar(assigns) do
    assigns =
      assigns
      |> assign(
        :current_user,
        if(assigns.current_scope, do: assigns.current_scope.user, else: nil)
      )

    ~H"""
    <header
      id={@id}
      class={[
        "fixed top-0 z-50 bg-base-100/85 backdrop-blur-md transition-all duration-300 shadow-sm",
        @sidebar_layout && "left-0 right-0 lg:left-80",
        !@sidebar_layout && "left-0 right-0",
        @class
      ]}
    >
      <div class="navbar mx-auto px-4 sm:px-6 lg:px-8 py-3">
        <div class="navbar-start gap-3">
          <.mobile_menu :if={@mobile_links != []} class="mr-1">
            {render_slot(@mobile_links)}
          </.mobile_menu>
          <.app_logo>
            <:logo>
              {render_slot(@logo_src)}
            </:logo>
            <:text :if={@logo_text != []}>
              {render_slot(@logo_text)}
            </:text>
          </.app_logo>
        </div>
        <div :if={@nav_links != []} class="navbar-center hidden lg:flex">
          <ul class="menu menu-horizontal px-1 gap-3">
            {render_slot(@nav_links)}
          </ul>
        </div>
        <div class="navbar-end gap-4">
          {render_slot(@actions)}
          <div :if={@current_user} class="dropdown dropdown-end">
            <label
              tabindex="0"
              class="btn btn-ghost btn-circle avatar group transition-all duration-300 hover:scale-105"
            >
              <div class="w-10 rounded-full ring-2 ring-primary ring-offset-base-100 ring-offset-2 shadow-md group-hover:ring-offset-4 group-hover:shadow-lg transition-all duration-300 overflow-hidden">
                <img src={ZiStudy.Accounts.get_profile_picture_url(@current_user)} alt="Profile" />
              </div>
            </label>
            <div
              tabindex="0"
              class="dropdown-content z-[1] menu shadow-lg bg-base-200 rounded-box w-64 mt-3 overflow-hidden border-2 border-base-300"
            >
              <div class="p-4 text-center bg-base-300/50">
                <div class="avatar mb-3">
                  <div class="w-16 h-16 rounded-full ring-2 ring-primary ring-offset-base-100 ring-offset-2 mx-auto shadow-md">
                    <img src={ZiStudy.Accounts.get_profile_picture_url(@current_user)} alt="Profile" />
                  </div>
                </div>
                <div class="font-bold text-lg">{@current_user.email}</div>
                <div class="text-xs opacity-70 mt-1">Member</div>
                <div class="mt-3 divider m-0"></div>
              </div>
              <div class="py-2 px-1">
                {render_slot(@profile_links)}
                <div class="divider my-1"></div>
                <li class="p-0">
                  <.link
                    href={@logout_path}
                    method="delete"
                    class="w-full text-left flex items-center gap-3 py-3 px-4 text-error hover:bg-base-300 transition-colors rounded-lg"
                    data-csrf={Plug.CSRFProtection.get_csrf_token()}
                  >
                    <.icon name="hero-arrow-right-on-rectangle-solid" class="size-5" />
                    <span>Logout</span>
                  </.link>
                </li>
              </div>
            </div>
          </div>
          <div :if={!@current_user} class="flex items-center gap-3">
            <.link href={@login_path} class="btn btn-ghost btn-sm">
              Log in
            </.link>
            <.link href={@register_path} class="btn btn-primary btn-sm">
              Register
            </.link>
          </div>
        </div>
      </div>
    </header>

    <script :if={@show_on_scroll}>
      // Topbar scroll behavior
      document.addEventListener("DOMContentLoaded", function() {
        const topbar = document.getElementById("<%= @id %>");
        let lastScrollTop = 0;

        window.addEventListener("scroll", function() {
          let scrollTop = window.scrollY || document.documentElement.scrollTop;

          if (scrollTop > 100) {
            if (scrollTop > lastScrollTop) {
              // Scrolling down
              topbar.style.transform = "translateY(-100%)";
            } else {
              // Scrolling up
              topbar.style.transform = "translateY(0)";
              topbar.classList.add("shadow-md");
            }
          } else {
            // At the top
            topbar.style.transform = "translateY(0)";
            topbar.classList.remove("shadow-md");
          }

          lastScrollTop = scrollTop;
        });
      });
    </script>
    """
  end

  @doc """
  Renders a mobile menu dropdown.

  ## Examples

      <.mobile_menu>
        <li><a href="/">Home</a></li>
        <li><a href="/about">About</a></li>
      </.mobile_menu>
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def mobile_menu(assigns) do
    ~H"""
    <div class={["dropdown lg:hidden", @class]}>
      <label tabindex="0" class="btn btn-ghost btn-circle hover:bg-base-200 transition-colors">
        <.icon name="hero-bars-3-mini" class="size-5 text-base-content" />
      </label>
      <ul
        tabindex="0"
        class="menu menu-sm dropdown-content mt-3 z-[1] p-3 shadow-lg bg-base-200/95 backdrop-blur-sm rounded-box w-56 border-2 border-base-300 gap-1"
      >
        {render_slot(@inner_block)}
      </ul>
    </div>
    """
  end

  @doc """
  Renders an application logo with optional text.

  ## Examples

      <.app_logo>
        <:logo>
          <img src={~p"/images/logo.svg"} alt="Logo" />
        </:logo>
        <:text>
          <span class="text-lg font-bold">MyApp</span>
        </:text>
      </.app_logo>
  """
  attr :class, :string, default: nil
  attr :href, :string, default: "/"

  slot :logo, required: true
  slot :text

  def app_logo(assigns) do
    ~H"""
    <a
      href={@href}
      class={["flex items-center gap-3 transition-transform duration-300 hover:scale-105", @class]}
    >
      <div class="avatar">
        <div class="w-10 rounded-full ring-2 ring-primary ring-offset-base-100 ring-offset-2 bg-base-300 flex items-center justify-center shadow-md overflow-hidden">
          {render_slot(@logo)}
        </div>
      </div>
      <div :if={@text != []} class="hidden md:flex flex-col">
        {render_slot(@text)}
      </div>
    </a>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark-solid" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch)
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{"primary" => "btn-primary", nil => "btn-primary btn-soft"}
    assigns = assign(assigns, :class, Map.fetch!(variants, assigns[:variant]))

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={["btn", @class]} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={["btn", @class]} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <fieldset class="fieldset mb-2">
      <label>
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <span class="fieldset-label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class="checkbox checkbox-sm"
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <fieldset class="fieldset mb-2">
      <label>
        <span :if={@label} class="fieldset-label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={["w-full select", @errors != [] && "select-error"]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <fieldset class="fieldset mb-2">
      <label>
        <span :if={@label} class="fieldset-label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={["w-full textarea", @errors != [] && "textarea-error"]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <fieldset class="fieldset mb-2">
      <label>
        <span :if={@label} class="fieldset-label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={["w-full input", @errors != [] && "input-error"]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle-mini" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div>
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(ZiStudyWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ZiStudyWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
