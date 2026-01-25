defmodule Cuisine13Web.PrepTimelineLive do
  use Cuisine13Web, :live_view

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Prep Timeline")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-white pb-20">
      <div class="max-w-2xl mx-auto px-4 py-6">
        <h1 class="text-3xl font-bold mb-6">Prep Timeline</h1>
        <div class="text-center py-12">
          <p class="text-gray-400 text-lg">Prep Timeline Coming Soon</p>
        </div>
      </div>
    </div>
    """
  end
end
