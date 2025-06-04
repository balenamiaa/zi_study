defmodule ZiStudyWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use ZiStudyWeb, :html

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
        <li><a href={~p"/active-learning"} class="font-medium">Active Learning</a></li>
      </:nav_links>
      <:mobile_links>
        <li><a href="/" class="font-medium">Home</a></li>
        <li><a href={~p"/active-learning"} class="font-medium">Active Learning</a></li>
      </:mobile_links>
      <:profile_links>
        <li>
          <a href={~p"/users/settings"} class="flex gap-3 py-3">
            <.icon name="hero-cog-8-tooth-solid" class="size-5 text-base-content/70" />
            <span>Settings</span>
          </a>
        </li>
      </:profile_links>
      <:actions>
        <.theme_toggle />
      </:actions>
    </.topbar>

    <main class="container mx-auto px-4 py-12 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  def active_learning(assigns) do
    ~H"""
    <.topbar
      current_scope={@current_scope}
      login_path={~p"/users/log-in"}
      register_path={~p"/users/register"}
      logout_path={~p"/users/log-out"}
      sidebar_layout={true}
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
        <li><a href={~p"/active-learning"} class="font-medium text-primary">Active Learning</a></li>
      </:nav_links>
      <:mobile_links>
        <li><a href="/" class="font-medium">Home</a></li>
        <li><a href={~p"/active-learning"} class="font-medium text-primary">Active Learning</a></li>
      </:mobile_links>
      <:profile_links>
        <li>
          <a href={~p"/users/settings"} class="flex gap-3 py-3">
            <.icon name="hero-cog-8-tooth-solid" class="size-5 text-base-content/70" />
            <span>Settings</span>
          </a>
        </li>
      </:profile_links>
      <:actions>
        <.theme_toggle />
      </:actions>
    </.topbar>

    <div
      id="sidebar-overlay"
      class="fixed inset-0 bg-black/50 backdrop-blur-sm z-40 lg:hidden opacity-0 invisible transition-all duration-300"
      onclick="closeSidebar()"
    >
    </div>

    <!-- Desktop Layout Container -->
    <div class="lg:flex lg:h-screen">
      <!-- Sidebar - Fixed overlay on mobile, static on desktop -->
      <aside
        id="sidebar"
        class="fixed top-0 left-0 h-screen w-80 bg-base-200/95 backdrop-blur-md border-r border-base-300 z-50 transform -translate-x-full transition-transform duration-300 shadow-2xl lg:relative lg:translate-x-0 lg:shadow-lg lg:bg-base-200 lg:backdrop-blur-none"
      >
        <div class="flex flex-col h-full pt-20">
          <div class="px-6 py-4 border-b border-base-300/50">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-primary to-secondary flex items-center justify-center shadow-md">
                <.icon name="hero-academic-cap-solid" class="size-6 text-white" />
              </div>
              <div>
                <h2 class="text-lg font-bold text-base-content">Active Learning</h2>
                <p class="text-xs text-base-content/70">Study & Practice</p>
              </div>
            </div>
          </div>

          <nav class="flex-1 px-4 py-6 space-y-2 overflow-y-auto">
            <div class="space-y-1">
              <h3 class="px-3 text-xs font-semibold text-base-content/60 uppercase tracking-wider mb-3">
                Question Sets
              </h3>
              <a
                href={~p"/active-learning"}
                class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 hover:bg-base-300/60 text-base-content hover:text-primary group"
              >
                <.icon
                  name="hero-squares-2x2-mini"
                  class="size-5 text-base-content/70 group-hover:text-primary"
                />
                <span>Browse Sets</span>
              </a>
              <a
                href="#"
                class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 hover:bg-base-300/60 text-base-content hover:text-primary group"
              >
                <.icon
                  name="hero-plus-mini"
                  class="size-5 text-base-content/70 group-hover:text-primary"
                />
                <span>Create Set</span>
              </a>
              <a
                href="#"
                class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 hover:bg-base-300/60 text-base-content hover:text-primary group"
              >
                <.icon
                  name="hero-heart-mini"
                  class="size-5 text-base-content/70 group-hover:text-primary"
                />
                <span>Favorites</span>
              </a>
            </div>

            <div class="pt-6 space-y-1">
              <h3 class="px-3 text-xs font-semibold text-base-content/60 uppercase tracking-wider mb-3">
                Study Tools
              </h3>
              <a
                href="#"
                class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 hover:bg-base-300/60 text-base-content hover:text-primary group"
              >
                <.icon
                  name="hero-chart-bar-mini"
                  class="size-5 text-base-content/70 group-hover:text-primary"
                />
                <span>Progress</span>
              </a>
              <a
                href="#"
                class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 hover:bg-base-300/60 text-base-content hover:text-primary group"
              >
                <.icon
                  name="hero-fire-mini"
                  class="size-5 text-base-content/70 group-hover:text-primary"
                />
                <span>Streak</span>
              </a>
              <a
                href="#"
                class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 hover:bg-base-300/60 text-base-content hover:text-primary group"
              >
                <.icon
                  name="hero-calendar-days-mini"
                  class="size-5 text-base-content/70 group-hover:text-primary"
                />
                <span>Schedule</span>
              </a>
            </div>

            <div class="pt-6 space-y-1">
              <h3 class="px-3 text-xs font-semibold text-base-content/60 uppercase tracking-wider mb-3">
                Community
              </h3>
              <a
                href="#"
                class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 hover:bg-base-300/60 text-base-content hover:text-primary group"
              >
                <.icon
                  name="hero-users-mini"
                  class="size-5 text-base-content/70 group-hover:text-primary"
                />
                <span>Public Sets</span>
              </a>
              <a
                href="#"
                class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 hover:bg-base-300/60 text-base-content hover:text-primary group"
              >
                <.icon
                  name="hero-share-mini"
                  class="size-5 text-base-content/70 group-hover:text-primary"
                />
                <span>Shared with Me</span>
              </a>
            </div>
          </nav>

          <div class="px-6 py-4 border-t border-base-300/50">
            <div class="flex items-center gap-3 text-sm text-base-content/70">
              <.icon name="hero-light-bulb-mini" class="size-4" />
              <span>Need help? Check our guides</span>
            </div>
          </div>
        </div>
      </aside>

    <!-- Main content area -->
      <div class="flex-1 min-h-screen lg:overflow-y-auto">
        <main class="px-4 py-12 sm:px-6 lg:px-8">
          <div class="mx-auto max-w-6xl space-y-6">
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>
    </div>

    <!-- Wrapped Paper Edge - Always visible sidebar trigger -->
    <div
      id="paper-edge"
      class="fixed top-1/2 left-0 z-30 lg:hidden cursor-pointer transform -translate-y-1/2 transition-all duration-300 hover:scale-110 group"
      onclick="openSidebar()"
    >
      <div class="w-8 h-16 bg-gradient-to-r from-base-100 to-base-200 shadow-lg border-r border-t border-b border-base-300 rounded-r-lg relative overflow-hidden">

    <!-- Subtle grip dots -->
        <div class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
          <div class="flex flex-col gap-1">
            <div class="w-1 h-1 bg-base-content/20 rounded-full"></div>
            <div class="w-1 h-1 bg-base-content/20 rounded-full"></div>
            <div class="w-1 h-1 bg-base-content/20 rounded-full"></div>
          </div>
        </div>

    <!-- Glow effect on hover -->
        <div class="absolute inset-0 bg-primary/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-r-lg">
        </div>

    <!-- Shadow beneath -->
        <div class="absolute top-1 left-1 w-8 h-16 bg-black/10 rounded-r-lg -z-10"></div>

    <!-- Tooltip - now shows on group hover -->
        <div class="absolute left-10 top-1/2 transform -translate-y-1/2 bg-base-300 text-base-content text-xs px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition-opacity duration-300 whitespace-nowrap shadow-lg">
          Open sidebar
        </div>
      </div>
    </div>

    <.flash_group flash={@flash} />

    <script>
      function toggleSidebar() {
        const sidebar = document.getElementById('sidebar');
        const overlay = document.getElementById('sidebar-overlay');

        if (sidebar.classList.contains('-translate-x-full')) {
          openSidebar();
        } else {
          closeSidebar();
        }
      }

            function openSidebar() {
        const sidebar = document.getElementById('sidebar');
        const overlay = document.getElementById('sidebar-overlay');
        const paperEdge = document.getElementById('paper-edge');

        sidebar.classList.remove('-translate-x-full');
        overlay.classList.remove('opacity-0', 'invisible');
        overlay.classList.add('opacity-100', 'visible');
        paperEdge.classList.add('opacity-0', 'invisible');
        document.body.style.overflow = 'hidden';
      }

            function closeSidebar() {
        const sidebar = document.getElementById('sidebar');
        const overlay = document.getElementById('sidebar-overlay');
        const paperEdge = document.getElementById('paper-edge');

        sidebar.classList.add('-translate-x-full');
        overlay.classList.add('opacity-0', 'invisible');
        overlay.classList.remove('opacity-100', 'visible');
        paperEdge.classList.remove('opacity-0', 'invisible');
        document.body.style.overflow = '';
      }

      document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
          closeSidebar();
        }
      });

      window.addEventListener('resize', function() {
        if (window.innerWidth >= 1024) {
          closeSidebar();
          document.body.style.overflow = '';
        }
      });
    </script>
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
