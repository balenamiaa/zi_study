defmodule ZistudyWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use ZistudyWeb, :html

  embed_templates "layouts/*"

  def app(assigns) do
    ~H"""
    <.topbar
      current_scope={@current_scope}
      login_path={~p"/users/log-in"}
      register_path={~p"/users/register"}
      logout_path={~p"/users/log-out"}
    >
      <:logo_src>
        <img src={~p"/images/logo.svg"} alt="ZiStudy Logo" class="w-6 h-6" />
      </:logo_src>
      <:logo_text>
        <span class="text-lg font-bold">ZiStudy</span>
        <span class="text-xs opacity-70">v{Application.spec(:phoenix, :vsn)}</span>
      </:logo_text>
      <:nav_links>
        <li><a href="/" class="font-medium">Home</a></li>
        <li><a href="/about" class="font-medium">About</a></li>
        <li><a href="/features" class="font-medium">Features</a></li>
      </:nav_links>
      <:mobile_links>
        <li><a href="/" class="font-medium">Home</a></li>
        <li><a href="/about" class="font-medium">About</a></li>
        <li><a href="/features" class="font-medium">Features</a></li>
      </:mobile_links>
      <:profile_links>
        <li>
          <a href={~p"/users/settings"} class="flex gap-3 py-3">
            <.icon name="hero-cog-8-tooth-solid" class="size-5 text-base-content/70" />
            <span>Settings</span>
          </a>
        </li>
        <li>
          <a href={~p"/profile"} class="flex gap-3 py-3">
            <.icon name="hero-user-solid" class="size-5 text-base-content/70" />
            <span>Profile</span>
          </a>
        </li>
        <li>
          <a href={~p"/dashboard"} class="flex gap-3 py-3">
            <.icon name="hero-chart-bar-solid" class="size-5 text-base-content/70" />
            <span>Dashboard</span>
          </a>
        </li>
      </:profile_links>
      <:actions>
        <.theme_toggle />
      </:actions>
    </.topbar>

    <main class="container mx-auto px-4 py-24 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-200 rounded-full shadow-md overflow-hidden">
      <div class="absolute w-[33%] h-full rounded-full bg-base-100 brightness-150 left-0 [[data-theme=light]_&]:left-[33%] [[data-theme=dark]_&]:left-[66%] transition-all duration-300" />

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})}
        class="flex p-2 z-10 hover:text-primary transition-colors duration-200"
      >
        <.icon name="hero-computer-desktop-mini" class="size-4 opacity-80 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})}
        class="flex p-2 z-10 hover:text-primary transition-colors duration-200"
      >
        <.icon name="hero-sun-mini" class="size-4 opacity-80 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})}
        class="flex p-2 z-10 hover:text-primary transition-colors duration-200"
      >
        <.icon name="hero-moon-mini" class="size-4 opacity-80 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
