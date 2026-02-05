defmodule Cuisine13.RecipeGenerationWorker do
  @moduledoc """
  GenServer that periodically generates new recipes using Claude AI.
  Runs in the background and creates recipes for households with API keys.
  """

  use GenServer
  require Logger
  alias Cuisine13.RecipeGenerator

  # Run every 4 hours (in milliseconds)
  @generation_interval 4 * 60 * 60 * 1000

  # For initial generation, wait 5 minutes after startup
  @initial_delay 5 * 60 * 1000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Schedule the first generation
    schedule_generation(@initial_delay)
    Logger.info("Recipe generation worker started. First generation in #{@initial_delay / 1000 / 60} minutes")
    {:ok, %{}}
  end

  @impl true
  def handle_info(:generate_recipes, state) do
    Logger.info("Starting automatic recipe generation...")

    Task.start(fn ->
      try do
        RecipeGenerator.generate_for_all_households(2)  # Generate 2 recipes per household
      rescue
        e ->
          Logger.error("Recipe generation failed: #{inspect(e)}")
      end
    end)

    # Schedule the next generation
    schedule_generation(@generation_interval)

    {:noreply, state}
  end

  defp schedule_generation(delay) do
    Process.send_after(self(), :generate_recipes, delay)
  end

  @doc """
  Manually trigger recipe generation (useful for testing).
  """
  def generate_now do
    send(__MODULE__, :generate_recipes)
  end
end
