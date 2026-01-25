defmodule Cuisine13Web.GroceriesLive do
  use Cuisine13Web, :live_view

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Groceries")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-white pb-20">
      <div class="max-w-2xl mx-auto px-4 py-6">
        <h1 class="text-3xl font-bold mb-6">Grocery List</h1>
        <div class="text-center py-12">
          <svg class="w-16 h-16 mx-auto text-gray-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"/>
          </svg>
          <p class="text-gray-400 text-lg">Grocery List Coming Soon</p>
        </div>
      </div>
      <%= render_nav(assigns) %>
    </div>
    """
  end

  defp render_nav(assigns) do
    ~H"""
    <nav class="fixed bottom-0 left-0 right-0 bg-gray-800/95 backdrop-blur-lg border-t border-gray-700">
      <div class="max-w-2xl mx-auto px-6 py-3">
        <div class="flex items-center justify-around">
          <%= live_redirect to: "/", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>
            <span class="text-xs font-medium">Feed</span>
          <% end %>
          <%= live_redirect to: "/recipes/saved", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/></svg>
            <span class="text-xs font-medium">Saved</span>
          <% end %>
          <%= live_redirect to: "/calendar", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            <span class="text-xs font-medium">Calendar</span>
          <% end %>
          <a href="/groceries" class="flex flex-col items-center gap-1 text-purple-400">
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20"><path d="M3 1a1 1 0 000 2h1.22l.305 1.222a.997.997 0 00.01.042l1.358 5.43-.893.892C3.74 11.846 4.632 14 6.414 14H15a1 1 0 000-2H6.414l1-1H14a1 1 0 00.894-.553l3-6A1 1 0 0017 3H6.28l-.31-1.243A1 1 0 005 1H3zM16 16.5a1.5 1.5 0 11-3 0 1.5 1.5 0 013 0zM6.5 18a1.5 1.5 0 100-3 1.5 1.5 0 000 3z"/></svg>
            <span class="text-xs font-medium">Groceries</span>
          </a>
          <%= live_redirect to: "/users/settings", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
            <span class="text-xs font-medium">Profile</span>
          <% end %>
        </div>
      </div>
    </nav>
    """
  end
end
