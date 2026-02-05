defmodule Cuisine13Web.SettingsLive do
  use Cuisine13Web, :live_view
  alias Cuisine13.Households

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    household = get_household(current_user)

    changeset = Households.change_api_keys(household)

    {:ok,
     socket
     |> assign(:page_title, "API Settings")
     |> assign(:household, household)
     |> assign(:changeset, changeset)}
  end

  defp get_household(user) do
    case Households.list_households_for_user(user.id) do
      [household | _] -> household
      [] -> nil
    end
  end

  @impl true
  def handle_event("validate", %{"household" => household_params}, socket) do
    changeset =
      socket.assigns.household
      |> Households.change_api_keys(household_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"household" => household_params}, socket) do
    case Households.update_api_keys(socket.assigns.household, household_params) do
      {:ok, household} ->
        {:noreply,
         socket
         |> assign(:household, household)
         |> put_flash(:info, "API keys updated successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="min-h-screen bg-gray-950 text-white">
      <!-- Header -->
      <header class="bg-gray-900/95 backdrop-blur-sm border-b border-gray-800" style="padding-top: max(1rem, env(safe-area-inset-top))">
        <div class="max-w-7xl mx-auto px-4 py-3">
          <div class="flex items-center gap-4">
            <%= live_redirect to: "/", class: "text-gray-400 hover:text-white transition-colors p-1" do %>
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
              </svg>
            <% end %>
            <h1 class="text-xl font-semibold flex-1">API Settings</h1>
          </div>
        </div>
      </header>

      <main class="max-w-2xl mx-auto px-4 py-6 pb-24">
        <%= if @household do %>
          <div class="bg-gray-900 rounded-2xl p-6 border border-gray-800 mb-6">
            <div class="flex items-start gap-3 mb-4">
              <svg class="w-6 h-6 text-blue-500 flex-shrink-0 mt-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              <div class="text-sm text-gray-400">
                <p class="mb-2">Configure API keys for your household. These keys enable AI-powered features like recipe generation and restaurant recommendations.</p>
                <p class="text-yellow-400">⚠️ Keep your API keys secure. They are stored in your household settings.</p>
              </div>
            </div>
          </div>

          <%= f = form_for @changeset, "#", [phx_change: "validate", phx_submit: "save", class: "space-y-6"] %>
            <div class="bg-gray-900 rounded-2xl p-6 border border-gray-800 space-y-6">
              <div>
                <div class="flex items-center gap-2 mb-2">
                  <%= label f, :anthropic_api_key, "Anthropic API Key", class: "block text-sm font-medium text-gray-300" %>
                  <%= if @household.anthropic_api_key do %>
                    <span class="text-xs text-green-500 flex items-center gap-1">
                      <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                      </svg>
                      Configured
                    </span>
                  <% end %>
                  <a href="https://console.anthropic.com/settings/keys" target="_blank" rel="noopener noreferrer" class="text-xs text-blue-500 hover:text-blue-400">
                    Get key →
                  </a>
                </div>
                <%= password_input f, :anthropic_api_key,
                  class: "w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500",
                  placeholder: if(@household.anthropic_api_key, do: "••••••••••••••••••••", else: "sk-ant-api03-...") %>
                <p class="text-xs text-gray-500 mt-1">Used for AI recipe generation, ingredient parsing, and recipe analysis</p>
                <%= error_tag f, :anthropic_api_key %>
              </div>

              <div>
                <div class="flex items-center gap-2 mb-2">
                  <%= label f, :yelp_api_key, "Yelp API Key", class: "block text-sm font-medium text-gray-300" %>
                  <%= if @household.yelp_api_key do %>
                    <span class="text-xs text-green-500 flex items-center gap-1">
                      <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                      </svg>
                      Configured
                    </span>
                  <% end %>
                  <a href="https://www.yelp.com/developers/v3/manage_app" target="_blank" rel="noopener noreferrer" class="text-xs text-blue-500 hover:text-blue-400">
                    Get key →
                  </a>
                </div>
                <%= password_input f, :yelp_api_key,
                  class: "w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500",
                  placeholder: if(@household.yelp_api_key, do: "••••••••••••••••••••", else: "Enter your Yelp API key") %>
                <p class="text-xs text-gray-500 mt-1">Used for restaurant recommendations and trending dishes near you</p>
                <%= error_tag f, :yelp_api_key %>
              </div>

              <div>
                <div class="flex items-center gap-2 mb-2">
                  <%= label f, :google_places_api_key, "Google Places API Key", class: "block text-sm font-medium text-gray-300" %>
                  <%= if @household.google_places_api_key do %>
                    <span class="text-xs text-green-500 flex items-center gap-1">
                      <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                      </svg>
                      Configured
                    </span>
                  <% end %>
                  <a href="https://console.cloud.google.com/apis/credentials" target="_blank" rel="noopener noreferrer" class="text-xs text-blue-500 hover:text-blue-400">
                    Get key →
                  </a>
                </div>
                <%= password_input f, :google_places_api_key,
                  class: "w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500",
                  placeholder: if(@household.google_places_api_key, do: "••••••••••••••••••••", else: "Enter your Google Places API key") %>
                <p class="text-xs text-gray-500 mt-1">Used for location-based restaurant search and place details</p>
                <%= error_tag f, :google_places_api_key %>
              </div>

              <div class="flex gap-4 pt-4">
                <%= submit "Save API Keys",
                  phx_disable_with: "Saving...",
                  class: "flex-1 py-3 px-4 bg-blue-600 hover:bg-blue-500 text-white font-semibold rounded-lg transition-colors" %>
              </div>
            </div>
          </form>

          <div class="bg-gray-900 rounded-2xl p-6 border border-gray-800 mt-6">
            <h2 class="text-lg font-semibold mb-3">About These API Keys</h2>
            <div class="space-y-3 text-sm text-gray-400">
              <div>
                <strong class="text-white">Anthropic Claude:</strong> Powers AI recipe generation, intelligent ingredient parsing, and recipe analysis.
              </div>
              <div>
                <strong class="text-white">Yelp:</strong> Provides restaurant data, trending dishes, and local food recommendations.
              </div>
              <div>
                <strong class="text-white">Google Places:</strong> Enables location search and detailed place information.
              </div>
            </div>
          </div>
        <% else %>
          <div class="bg-gray-900 rounded-2xl p-6 border border-gray-800">
            <p class="text-gray-400">You need to create or join a household first to configure API keys.</p>
            <%= live_redirect "Go to Household Settings", to: "/household", class: "inline-block mt-4 py-2 px-4 bg-blue-600 hover:bg-blue-500 text-white font-semibold rounded-lg transition-colors" %>
          </div>
        <% end %>
      </main>
    </div>
    """
  end
end
