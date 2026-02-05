defmodule Cuisine13Web.CookingModeLive do
  use Cuisine13Web, :live_view

  alias Cuisine13.Recipes

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Recipes.get_recipe(id) do
      nil ->
        socket =
          socket
          |> put_flash(:error, "Recipe not found")
          |> redirect(to: "/")

        {:ok, socket}

      recipe ->
        instructions = Enum.sort_by(recipe.instructions, & &1.step_number)

        socket =
          socket
          |> assign(:recipe, recipe)
          |> assign(:page_title, "Cooking: #{recipe.title}")
          |> assign(:instructions, instructions)
          |> assign(:current_step, 0)
          |> assign(:total_steps, length(instructions))
          |> assign(:timer_running, false)
          |> assign(:timer_seconds, 0)
          |> assign(:timer_duration, nil)

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("next_step", _params, socket) do
    current = socket.assigns.current_step
    total = socket.assigns.total_steps

    if current < total - 1 do
      {:noreply, assign(socket, current_step: current + 1, timer_running: false, timer_seconds: 0)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("prev_step", _params, socket) do
    current = socket.assigns.current_step

    if current > 0 do
      {:noreply, assign(socket, current_step: current - 1, timer_running: false, timer_seconds: 0)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("go_to_step", %{"step" => step_str}, socket) do
    case Integer.parse(step_str) do
      {step, ""} ->
        total = socket.assigns.total_steps

        if step >= 0 && step < total do
          {:noreply, assign(socket, current_step: step, timer_running: false, timer_seconds: 0)}
        else
          {:noreply, socket}
        end

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white flex flex-col">
      <!-- Header -->
      <header class="bg-gray-900/95 backdrop-blur-sm border-b border-gray-800 px-4 py-3" style="padding-top: max(1rem, env(safe-area-inset-top))">
        <div class="flex items-center justify-between">
          <%= live_redirect to: "/recipes/#{@recipe.id}", class: "p-2 hover:bg-gray-800 rounded-lg transition-colors" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          <% end %>
          <h1 class="text-lg font-semibold truncate px-4 flex-1 text-center"><%= @recipe.title %></h1>
          <div class="w-10"></div>
        </div>

        <!-- Progress Bar -->
        <div class="mt-4">
          <div class="flex items-center justify-between text-sm text-gray-400 mb-2">
            <span>Step <%= @current_step + 1 %> of <%= @total_steps %></span>
            <span><%= round((@current_step + 1) / @total_steps * 100) %>%</span>
          </div>
          <div class="w-full bg-gray-800 rounded-full h-2">
            <div
              class="bg-gradient-to-r from-blue-600 to-purple-600 h-2 rounded-full transition-all duration-300"
              style={"width: #{(@current_step + 1) / @total_steps * 100}%"}
            ></div>
          </div>
        </div>
      </header>

      <!-- Main Content - Current Step -->
      <main class="flex-1 flex flex-col justify-center px-6 py-8 overflow-y-auto" style="padding-top: max(6rem, calc(6rem + env(safe-area-inset-top)))">
        <%= if @current_step < @total_steps do %>
          <% instruction = Enum.at(@instructions, @current_step) %>

          <!-- Step Number Badge -->
          <div class="flex justify-center mb-6">
            <div class="w-20 h-20 rounded-full bg-gradient-to-br from-blue-600 to-purple-600 flex items-center justify-center">
              <span class="text-3xl font-bold"><%= instruction.step_number %></span>
            </div>
          </div>

          <!-- Instruction Text -->
          <div class="max-w-2xl mx-auto w-full">
            <p class="text-2xl md:text-3xl leading-relaxed text-center text-gray-100 font-medium">
              <%= instruction.description %>
            </p>

            <%= if instruction.duration_minutes do %>
              <div class="mt-8 flex items-center justify-center gap-3 text-blue-400">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
                <span class="text-xl"><%= instruction.duration_minutes %> minutes</span>
              </div>
            <% end %>
          </div>
        <% end %>
      </main>

      <!-- Navigation Controls -->
      <nav class="mobile-nav bg-gray-900/95 backdrop-blur-lg border-t border-gray-800 px-6 py-6">
        <div class="max-w-2xl mx-auto flex items-center gap-4">
          <!-- Previous Button -->
          <button
            phx-click="prev_step"
            disabled={@current_step == 0}
            class={"flex-1 py-4 px-6 rounded-xl font-semibold transition-all flex items-center justify-center gap-2 " <>
                   if(@current_step == 0, do: "bg-gray-800 text-gray-600 cursor-not-allowed", else: "bg-gray-800 hover:bg-gray-700 text-white active:scale-95")}
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
            </svg>
            <span class="text-lg">Previous</span>
          </button>

          <!-- Step Indicator Dots -->
          <div class="flex gap-2">
            <%= for step <- 0..(@total_steps - 1) do %>
              <button
                phx-click="go_to_step"
                phx-value-step={step}
                class={"w-3 h-3 rounded-full transition-all " <>
                       if(step == @current_step, do: "bg-blue-500 scale-125", else: if(step < @current_step, do: "bg-green-500", else: "bg-gray-700"))}
              >
              </button>
            <% end %>
          </div>

          <!-- Next Button -->
          <button
            phx-click="next_step"
            disabled={@current_step >= @total_steps - 1}
            class={"flex-1 py-4 px-6 rounded-xl font-semibold transition-all flex items-center justify-center gap-2 " <>
                   if(@current_step >= @total_steps - 1, do: "bg-gray-800 text-gray-600 cursor-not-allowed", else: "bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-500 hover:to-purple-500 text-white active:scale-95")}
          >
            <span class="text-lg">
              <%= if @current_step >= @total_steps - 1, do: "Done!", else: "Next" %>
            </span>
            <%= if @current_step < @total_steps - 1 do %>
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
              </svg>
            <% end %>
          </button>
        </div>

        <!-- Completion Message -->
        <%= if @current_step >= @total_steps - 1 do %>
          <div class="mt-4 text-center">
            <p class="text-gray-400">All steps complete!</p>
            <%= live_redirect to: "/recipes/#{@recipe.id}", class: "inline-block mt-2 text-blue-500 hover:text-blue-400" do %>
              Return to Recipe →
            <% end %>
          </div>
        <% end %>
      </nav>
    </div>
    """
  end
end
