defmodule Cuisine13Web.HouseholdLive do
  use Cuisine13Web, :live_view

  alias Cuisine13.Households

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    households = Households.list_households_for_user(current_user.id)
    household = List.first(households)

    socket =
      socket
      |> assign(:page_title, "Household")
      |> assign(:household, household)
      |> assign(:join_code, "")
      |> assign(:join_error, nil)
      |> assign(:show_join_form, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_join_form", _params, socket) do
    {:noreply, assign(socket, :show_join_form, !socket.assigns.show_join_form)}
  end

  @impl true
  def handle_event("update_join_code", %{"code" => code}, socket) do
    {:noreply, assign(socket, :join_code, String.upcase(code))}
  end

  @impl true
  def handle_event("join_household", _params, socket) do
    code = socket.assigns.join_code
    user_id = socket.assigns.current_user.id

    case Households.join_household_by_code(String.downcase(code), user_id) do
      {:ok, _membership} ->
        households = Households.list_households_for_user(user_id)
        household = List.first(households)

        {:noreply,
         socket
         |> assign(:household, household)
         |> assign(:join_code, "")
         |> assign(:join_error, nil)
         |> assign(:show_join_form, false)
         |> put_flash(:info, "Successfully joined household!")}

      {:error, :invalid_code} ->
        {:noreply, assign(socket, :join_error, "Invalid invite code")}

      {:error, :already_member} ->
        {:noreply, assign(socket, :join_error, "You're already a member of this household")}

      {:error, _} ->
        {:noreply, assign(socket, :join_error, "Something went wrong")}
    end
  end

  @impl true
  def handle_event("regenerate_code", _params, socket) do
    case Households.regenerate_invite_code(socket.assigns.household) do
      {:ok, household} ->
        {:noreply,
         socket
         |> assign(:household, Households.get_household!(household.id))
         |> put_flash(:info, "Invite code regenerated!")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to regenerate code")}
    end
  end

  @impl true
  def handle_event("leave_household", _params, socket) do
    case Households.leave_household(socket.assigns.household.id, socket.assigns.current_user.id) do
      {:ok, _} ->
        # Create a new household for the user
        {:ok, new_household} =
          Households.create_household(%{name: "#{socket.assigns.current_user.email}'s Household"})

        {:ok, _} =
          Households.add_member(new_household.id, socket.assigns.current_user.id, "admin")

        {:noreply,
         socket
         |> assign(:household, Households.get_household!(new_household.id))
         |> put_flash(:info, "Left household. Created a new one for you.")}

      {:error, :last_admin} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "You can't leave - you're the only admin. Add another admin first or delete the household."
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to leave household")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white pb-20">
      <!-- Header -->
      <header class="bg-gray-900/95 backdrop-blur-sm border-b border-gray-800" style="padding-top: max(1rem, env(safe-area-inset-top))">
        <div class="max-w-2xl mx-auto px-4 py-3">
          <h1 class="text-2xl font-bold text-white">
            Household
          </h1>
        </div>
      </header>

      <main class="max-w-2xl mx-auto px-4 py-6 space-y-6 pb-24">
        <%= if @household do %>
          <!-- Current Household -->
          <div class="bg-gray-900 rounded-xl border border-gray-800 p-6">
            <h2 class="text-xl font-semibold mb-4"><%= @household.name %></h2>

            <!-- Members -->
            <div class="mb-6">
              <h3 class="text-sm font-medium text-gray-400 mb-3">Members</h3>
              <div class="space-y-2">
                <%= for user <- @household.users do %>
                  <div class="flex items-center gap-3 p-3 bg-gray-800/50 rounded-lg">
                    <div class="w-10 h-10 bg-blue-600 rounded-full flex items-center justify-center text-lg font-semibold">
                      <%= String.first(user.email) |> String.upcase() %>
                    </div>
                    <div class="flex-1">
                      <div class="font-medium"><%= user.email %></div>
                      <div class="text-sm text-gray-400">
                        <%= if Households.admin?(@household.id, user.id), do: "Admin", else: "Member" %>
                      </div>
                    </div>
                    <%= if user.id == @current_user.id do %>
                      <span class="text-xs text-blue-500 px-2 py-1 bg-blue-500/20 rounded">You</span>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>

            <!-- Invite Code -->
            <div class="mb-6 p-4 bg-gray-800/50 rounded-lg">
              <h3 class="text-sm font-medium text-gray-400 mb-2">Invite Code</h3>
              <p class="text-xs text-gray-500 mb-3">Share this code with your roommate so they can join your household.</p>
              <div class="flex items-center gap-3">
                <code class="flex-1 text-2xl font-mono font-bold text-blue-500 tracking-wider bg-gray-900 px-4 py-3 rounded-lg text-center">
                  <%= String.upcase(@household.invite_code || "--------") %>
                </code>
                <button
                  phx-click="regenerate_code"
                  class="p-3 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors"
                  title="Generate new code"
                >
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
                  </svg>
                </button>
              </div>
            </div>

            <!-- API Settings -->
            <div class="mb-6">
              <%= live_redirect to: "/settings/api", class: "flex items-center justify-between w-full p-4 bg-gray-800/50 hover:bg-gray-800 rounded-lg transition-colors group" do %>
                <div class="flex items-center gap-3">
                  <div class="p-2 bg-blue-600/20 rounded-lg">
                    <svg class="w-5 h-5 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"/>
                    </svg>
                  </div>
                  <div>
                    <h3 class="text-sm font-medium text-white">API Settings</h3>
                    <p class="text-xs text-gray-400">Configure Claude, Yelp, and Google API keys</p>
                  </div>
                </div>
                <svg class="w-5 h-5 text-gray-500 group-hover:text-gray-300 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                </svg>
              <% end %>
            </div>

            <!-- Leave Household -->
            <%= if length(@household.users) > 1 do %>
              <button
                phx-click="leave_household"
                data-confirm="Are you sure you want to leave this household?"
                class="w-full py-3 px-4 bg-red-600/20 hover:bg-red-600/30 text-red-400 font-medium rounded-lg transition-colors border border-red-600/30"
              >
                Leave Household
              </button>
            <% end %>
          </div>

          <!-- Join Another Household -->
          <div class="bg-gray-900 rounded-xl border border-gray-800 p-6">
            <button
              phx-click="toggle_join_form"
              class="flex items-center justify-between w-full"
            >
              <h2 class="text-lg font-semibold">Join Another Household</h2>
              <svg class={"w-5 h-5 transition-transform #{if @show_join_form, do: "rotate-180"}"} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
              </svg>
            </button>

            <%= if @show_join_form do %>
              <div class="mt-4 pt-4 border-t border-gray-800">
                <p class="text-sm text-gray-400 mb-4">Enter the invite code from your roommate to join their household. Your data will merge with theirs.</p>
                <div class="flex gap-3">
                  <input
                    type="text"
                    value={@join_code}
                    phx-keyup="update_join_code"
                    phx-key="Enter"
                    placeholder="Enter code"
                    maxlength="8"
                    class="flex-1 px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white text-center font-mono text-lg tracking-wider uppercase focus:outline-none focus:border-blue-500"
                  />
                  <button
                    phx-click="join_household"
                    class="px-6 py-3 bg-blue-600 hover:bg-blue-500 text-white font-semibold rounded-lg transition-colors"
                  >
                    Join
                  </button>
                </div>
                <%= if @join_error do %>
                  <p class="mt-2 text-sm text-red-400"><%= @join_error %></p>
                <% end %>
              </div>
            <% end %>
          </div>
        <% else %>
          <div class="text-center py-12">
            <p class="text-gray-400">No household found. Something went wrong.</p>
          </div>
        <% end %>
      </main>

      <%= render_nav(assigns) %>
    </div>
    """
  end

  defp render_nav(assigns) do
    ~H"""
    <nav class="fixed bottom-0 left-0 right-0 z-30 bg-gray-900/95 backdrop-blur-lg border-t border-gray-800">
      <div class="max-w-7xl mx-auto px-4">
        <div class="flex items-center justify-around py-3">
          <%= live_redirect to: "/", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white transition-colors" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
            </svg>
            <span class="text-xs font-medium">Feed</span>
          <% end %>
          <%= live_redirect to: "/recipes/saved", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white transition-colors" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/>
            </svg>
            <span class="text-xs font-medium">Saved</span>
          <% end %>
          <%= live_redirect to: "/calendar", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white transition-colors" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
            </svg>
            <span class="text-xs font-medium">Calendar</span>
          <% end %>
          <%= live_redirect to: "/groceries", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white transition-colors" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"/>
            </svg>
            <span class="text-xs font-medium">Groceries</span>
          <% end %>
          <%= live_redirect to: "/users/settings", class: "flex flex-col items-center gap-1 text-blue-500 transition-colors" do %>
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"/>
            </svg>
            <span class="text-xs font-medium">Profile</span>
          <% end %>
        </div>
      </div>
    </nav>
    """
  end
end
