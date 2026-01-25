defmodule Cuisine13Web.GroceriesLive do
  use Cuisine13Web, :live_view

  alias Cuisine13.{Groceries, Households, Pantry}

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    household = get_or_create_household(current_user)

    # Auto-generate grocery items for upcoming meals (next 2 weeks)
    Groceries.auto_generate_for_upcoming_meals(household.id, 14)

    grocery_items = Groceries.list_upcoming_grocery_items(household.id)
    items_by_category = Groceries.list_upcoming_items_by_category(household.id)

    socket =
      socket
      |> assign(:page_title, "Groceries")
      |> assign(:household, household)
      |> assign(:grocery_items, grocery_items)
      |> assign(:items_by_category, items_by_category)
      |> assign(:show_add_modal, false)
      |> assign_new_item_form()

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_purchased", %{"id" => id}, socket) do
    item = Groceries.get_grocery_item!(id)

    if item.is_purchased do
      Groceries.mark_unpurchased(id)
    else
      Groceries.mark_purchased(id, socket.assigns.current_user.id)
    end

    grocery_items = Groceries.list_upcoming_grocery_items(socket.assigns.household.id)
    items_by_category = Groceries.list_upcoming_items_by_category(socket.assigns.household.id)

    {:noreply,
     socket
     |> assign(:grocery_items, grocery_items)
     |> assign(:items_by_category, items_by_category)}
  end

  @impl true
  def handle_event("delete_item", %{"id" => id}, socket) do
    item = Groceries.get_grocery_item!(id)
    {:ok, _} = Groceries.delete_grocery_item(item)

    grocery_items = Groceries.list_upcoming_grocery_items(socket.assigns.household.id)
    items_by_category = Groceries.list_upcoming_items_by_category(socket.assigns.household.id)

    {:noreply,
     socket
     |> assign(:grocery_items, grocery_items)
     |> assign(:items_by_category, items_by_category)}
  end

  @impl true
  def handle_event("open_add_modal", _params, socket) do
    {:noreply, assign(socket, :show_add_modal, true)}
  end

  @impl true
  def handle_event("close_add_modal", _params, socket) do
    {:noreply, socket |> assign(:show_add_modal, false) |> assign_new_item_form()}
  end

  @impl true
  def handle_event("refresh_list", _params, socket) do
    # Regenerate grocery items from upcoming meals
    Groceries.auto_generate_for_upcoming_meals(socket.assigns.household.id, 14)

    grocery_items = Groceries.list_upcoming_grocery_items(socket.assigns.household.id)
    items_by_category = Groceries.list_upcoming_items_by_category(socket.assigns.household.id)

    {:noreply,
     socket
     |> assign(:grocery_items, grocery_items)
     |> assign(:items_by_category, items_by_category)}
  end

  @impl true
  def handle_event("clear_purchased", _params, socket) do
    Groceries.clear_purchased_items(socket.assigns.household.id)

    grocery_items = Groceries.list_upcoming_grocery_items(socket.assigns.household.id)
    items_by_category = Groceries.list_upcoming_items_by_category(socket.assigns.household.id)

    {:noreply,
     socket
     |> assign(:grocery_items, grocery_items)
     |> assign(:items_by_category, items_by_category)}
  end

  @impl true
  def handle_event("add_to_pantry", %{"id" => id}, socket) do
    item = Groceries.get_grocery_item!(id)
    Pantry.add_from_grocery_item(item, socket.assigns.current_user.id)
    Groceries.delete_grocery_item(item)

    grocery_items = Groceries.list_upcoming_grocery_items(socket.assigns.household.id)
    items_by_category = Groceries.list_upcoming_items_by_category(socket.assigns.household.id)

    {:noreply,
     socket
     |> assign(:grocery_items, grocery_items)
     |> assign(:items_by_category, items_by_category)}
  end

  @impl true
  def handle_event("validate_item", %{"item" => item_params}, socket) do
    # Handle switching to custom unit mode when "custom" is selected
    new_item = case item_params["unit"] do
      "custom" ->
        item_params
        |> Map.put("unit_type", "custom")
        |> Map.put("unit", "")
      _ ->
        item_params
    end

    {:noreply, assign(socket, :new_item, new_item)}
  end

  @impl true
  def handle_event("add_item", %{"item" => item_params}, socket) do
    attrs =
      item_params
      |> Map.put("household_id", socket.assigns.household.id)
      |> Map.update("quantity", nil, fn
        "" -> nil
        val -> Decimal.new(val)
      end)

    case Groceries.create_grocery_item(attrs) do
      {:ok, _item} ->
        grocery_items = Groceries.list_upcoming_grocery_items(socket.assigns.household.id)
        items_by_category = Groceries.list_upcoming_items_by_category(socket.assigns.household.id)

        {:noreply,
         socket
         |> assign(:grocery_items, grocery_items)
         |> assign(:items_by_category, items_by_category)
         |> assign(:show_add_modal, false)
         |> assign_new_item_form()}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white">
      <!-- Header with iOS safe area -->
      <header class="mobile-header bg-gray-900/95 backdrop-blur-sm border-b border-gray-800">
        <div class="max-w-2xl mx-auto px-4 py-3">
          <div class="flex items-center justify-between">
            <h1 class="text-2xl font-bold bg-gradient-to-r from-purple-400 to-pink-500 bg-clip-text text-transparent">
              Grocery List
            </h1>
            <div class="flex gap-2">
              <button
                type="button"
                phx-click="refresh_list"
                class="p-3 bg-gray-700 hover:bg-gray-600 active:bg-gray-500 rounded-lg transition-colors min-w-[44px] min-h-[44px] flex items-center justify-center"
                title="Refresh from calendar"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
                </svg>
              </button>
              <%= if Enum.any?(@grocery_items, & &1.is_purchased) do %>
                <button
                  type="button"
                  phx-click="clear_purchased"
                  class="p-3 bg-gray-700 hover:bg-gray-600 active:bg-gray-500 rounded-lg transition-colors min-w-[44px] min-h-[44px] flex items-center justify-center"
                  title="Clear purchased items"
                >
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                  </svg>
                </button>
              <% end %>
              <button
                type="button"
                phx-click="open_add_modal"
                class="p-3 bg-purple-600 hover:bg-purple-700 active:bg-purple-800 rounded-lg transition-colors min-w-[44px] min-h-[44px] flex items-center justify-center"
                title="Add item"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                </svg>
              </button>
            </div>
          </div>
        </div>
      </header>

      <main class="max-w-2xl mx-auto px-4 py-6 mobile-content">
        <%= if Enum.empty?(@grocery_items) do %>
          <div class="text-center py-12">
            <svg class="w-16 h-16 mx-auto text-gray-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"/>
            </svg>
            <p class="text-gray-400 text-lg mb-4">No grocery items yet</p>
            <button
              type="button"
              phx-click="open_add_modal"
              class="px-6 py-4 bg-purple-600 hover:bg-purple-700 active:bg-purple-800 text-white font-semibold rounded-lg transition-colors min-h-[48px]"
            >
              Add Your First Item
            </button>
          </div>
        <% else %>
          <!-- Stats -->
          <div class="grid grid-cols-2 gap-4 mb-6">
            <div class="bg-gray-900 rounded-xl p-4 border border-gray-800">
              <div class="text-2xl font-bold text-purple-400">
                <%= Enum.count(@grocery_items, & &1.is_purchased) %>/<%= Enum.count(@grocery_items) %>
              </div>
              <div class="text-sm text-gray-400">Purchased</div>
            </div>
            <div class="bg-gray-900 rounded-xl p-4 border border-gray-800">
              <div class="text-2xl font-bold text-pink-400">
                <%= Enum.count(@items_by_category) %>
              </div>
              <div class="text-sm text-gray-400">Categories</div>
            </div>
          </div>

          <!-- Grocery Items by Category -->
          <div class="space-y-6">
            <%= for {category, items} <- Enum.sort(@items_by_category) do %>
              <div class="bg-gray-900 rounded-xl border border-gray-800 overflow-hidden">
                <div class="bg-gray-800/50 px-4 py-3 border-b border-gray-800">
                  <h2 class="text-lg font-semibold capitalize flex items-center justify-between">
                    <span><%= category || "Uncategorized" %></span>
                    <span class="text-sm font-normal text-gray-400">
                      <%= Enum.count(items, & &1.is_purchased) %>/<%= Enum.count(items) %>
                    </span>
                  </h2>
                </div>
                <div class="divide-y divide-gray-800">
                  <%= for item <- Enum.sort_by(items, & &1.is_purchased) do %>
                    <div class={"flex items-center gap-3 px-4 py-3 hover:bg-gray-800/50 transition-colors #{if item.is_purchased, do: "opacity-60"}"}>
                      <button
                        phx-click="toggle_purchased"
                        phx-value-id={item.id}
                        class="flex-shrink-0"
                      >
                        <%= if item.is_purchased do %>
                          <svg class="w-6 h-6 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                          </svg>
                        <% else %>
                          <svg class="w-6 h-6 text-gray-600 hover:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <circle cx="12" cy="12" r="10" stroke-width="2"/>
                          </svg>
                        <% end %>
                      </button>

                      <div class="flex-1 min-w-0">
                        <div class={"font-medium #{if item.is_purchased, do: "line-through text-gray-500", else: "text-white"}"}>
                          <%= item.name %>
                        </div>
                        <div class="text-sm text-gray-400 flex items-center gap-2">
                          <%= if item.quantity && item.unit do %>
                            <span><%= format_quantity(item.quantity) %> <%= item.unit %></span>
                          <% end %>
                          <%= if item.needed_by_date do %>
                            <span class="text-purple-400">
                              • Need by <%= Calendar.strftime(item.needed_by_date, "%b %d") %>
                            </span>
                          <% end %>
                        </div>
                      </div>

                      <div class="flex items-center gap-2">
                        <%= if item.is_purchased do %>
                          <button
                            phx-click="add_to_pantry"
                            phx-value-id={item.id}
                            class="flex-shrink-0 p-2 hover:bg-purple-500/20 rounded-lg transition-colors group"
                            title="Add to pantry"
                          >
                            <svg class="w-5 h-5 text-gray-400 group-hover:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"/>
                            </svg>
                          </button>
                        <% end %>
                        <button
                          phx-click="delete_item"
                          phx-value-id={item.id}
                          class="flex-shrink-0 p-2 hover:bg-red-500/20 rounded-lg transition-colors group"
                        >
                          <svg class="w-5 h-5 text-gray-400 group-hover:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                          </svg>
                        </button>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </main>

      <!-- Add Item Modal -->
      <%= if @show_add_modal do %>
        <div
          class="fixed inset-0 bg-black/80 z-40"
          phx-click="close_add_modal"
        ></div>

        <div class="fixed inset-x-4 top-1/2 -translate-y-1/2 md:inset-x-auto md:left-1/2 md:-translate-x-1/2 md:w-full md:max-w-md z-50">
          <div class="bg-gray-900 rounded-2xl shadow-2xl border border-gray-800">
            <div class="px-6 py-4 border-b border-gray-800 flex items-center justify-between">
              <h3 class="text-xl font-bold">Add Grocery Item</h3>
              <button
                phx-click="close_add_modal"
                class="p-2 hover:bg-gray-800 rounded-lg transition-colors"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                </svg>
              </button>
            </div>

            <form phx-submit="add_item" phx-change="validate_item" class="p-6 space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-300 mb-2">Item Name *</label>
                <input
                  type="text"
                  name="item[name]"
                  value={@new_item["name"] || ""}
                  class="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:border-purple-500 focus:outline-none"
                  required
                />
              </div>

              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-300 mb-2">Quantity</label>
                  <input
                    type="number"
                    step="0.01"
                    name="item[quantity]"
                    value={@new_item["quantity"] || ""}
                    class="w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white focus:border-purple-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-300 mb-2">Unit</label>
                  <%= if @new_item["unit_type"] == "custom" do %>
                    <input
                      type="text"
                      name="item[unit]"
                      value={@new_item["custom_unit"] || ""}
                      placeholder="Enter custom unit"
                      class="w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white focus:border-purple-500 focus:outline-none"
                    />
                    <input type="hidden" name="item[unit_type]" value="custom" />
                  <% else %>
                    <select
                      name="item[unit]"
                      class="w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white focus:border-purple-500 focus:outline-none"
                    >
                      <option value="">Select unit</option>
                      <optgroup label="Count">
                        <option value="each" selected={@new_item["unit"] == "each"}>each</option>
                        <option value="piece" selected={@new_item["unit"] == "piece"}>piece</option>
                        <option value="dozen" selected={@new_item["unit"] == "dozen"}>dozen</option>
                        <option value="bunch" selected={@new_item["unit"] == "bunch"}>bunch</option>
                        <option value="head" selected={@new_item["unit"] == "head"}>head</option>
                        <option value="clove" selected={@new_item["unit"] == "clove"}>clove</option>
                      </optgroup>
                      <optgroup label="Weight">
                        <option value="oz" selected={@new_item["unit"] == "oz"}>oz</option>
                        <option value="lb" selected={@new_item["unit"] == "lb"}>lb</option>
                        <option value="g" selected={@new_item["unit"] == "g"}>g</option>
                        <option value="kg" selected={@new_item["unit"] == "kg"}>kg</option>
                      </optgroup>
                      <optgroup label="Volume">
                        <option value="tsp" selected={@new_item["unit"] == "tsp"}>tsp</option>
                        <option value="tbsp" selected={@new_item["unit"] == "tbsp"}>tbsp</option>
                        <option value="fl oz" selected={@new_item["unit"] == "fl oz"}>fl oz</option>
                        <option value="cup" selected={@new_item["unit"] == "cup"}>cup</option>
                        <option value="pint" selected={@new_item["unit"] == "pint"}>pint</option>
                        <option value="quart" selected={@new_item["unit"] == "quart"}>quart</option>
                        <option value="gallon" selected={@new_item["unit"] == "gallon"}>gallon</option>
                        <option value="ml" selected={@new_item["unit"] == "ml"}>ml</option>
                        <option value="liter" selected={@new_item["unit"] == "liter"}>liter</option>
                      </optgroup>
                      <optgroup label="Packaging">
                        <option value="can" selected={@new_item["unit"] == "can"}>can</option>
                        <option value="bottle" selected={@new_item["unit"] == "bottle"}>bottle</option>
                        <option value="jar" selected={@new_item["unit"] == "jar"}>jar</option>
                        <option value="bag" selected={@new_item["unit"] == "bag"}>bag</option>
                        <option value="box" selected={@new_item["unit"] == "box"}>box</option>
                        <option value="package" selected={@new_item["unit"] == "package"}>package</option>
                        <option value="container" selected={@new_item["unit"] == "container"}>container</option>
                        <option value="carton" selected={@new_item["unit"] == "carton"}>carton</option>
                      </optgroup>
                      <option value="custom">+ Add custom unit</option>
                    </select>
                  <% end %>
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-300 mb-2">Category</label>
                <select
                  name="item[category]"
                  class="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:border-purple-500 focus:outline-none"
                >
                  <option value="">Select category</option>
                  <option value="produce">Produce</option>
                  <option value="dairy">Dairy</option>
                  <option value="meat">Meat</option>
                  <option value="pantry">Pantry</option>
                  <option value="bakery">Bakery</option>
                  <option value="frozen">Frozen</option>
                  <option value="other">Other</option>
                </select>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-300 mb-2">Need By Date</label>
                <input
                  type="date"
                  name="item[needed_by_date]"
                  value={@new_item["needed_by_date"] || ""}
                  class="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg text-white focus:border-purple-500 focus:outline-none"
                />
              </div>

              <div class="flex gap-3 pt-4">
                <button
                  type="button"
                  phx-click="close_add_modal"
                  class="flex-1 px-4 py-2 bg-gray-800 hover:bg-gray-700 text-white font-semibold rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="flex-1 px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white font-semibold rounded-lg transition-colors"
                >
                  Add Item
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>


      <%= render_nav(assigns) %>
    </div>
    """
  end

  defp get_or_create_household(user) do
    case Households.list_households_for_user(user.id) do
      [] ->
        {:ok, household} = Households.create_household(%{name: "#{user.email}'s Household"})
        {:ok, _membership} = Households.add_member(household.id, user.id, "admin")
        household

      [household | _] ->
        household
    end
  end

  defp assign_new_item_form(socket) do
    assign(socket, :new_item, %{
      "name" => "",
      "quantity" => "",
      "unit" => "",
      "unit_type" => nil,
      "custom_unit" => "",
      "category" => "",
      "needed_by_date" => ""
    })
  end

  defp format_quantity(nil), do: ""

  defp format_quantity(quantity) when is_struct(quantity, Decimal) do
    float_val = Decimal.to_float(quantity)

    cond do
      float_val == Float.round(float_val) ->
        float_val |> trunc() |> to_string()

      abs(float_val - 0.25) < 0.01 -> "1/4"
      abs(float_val - 0.33) < 0.02 -> "1/3"
      abs(float_val - 0.5) < 0.01 -> "1/2"
      abs(float_val - 0.67) < 0.02 -> "2/3"
      abs(float_val - 0.75) < 0.01 -> "3/4"

      float_val > 1 ->
        whole = trunc(float_val)
        fraction = float_val - whole

        fraction_str =
          cond do
            abs(fraction - 0.25) < 0.01 -> "1/4"
            abs(fraction - 0.33) < 0.02 -> "1/3"
            abs(fraction - 0.5) < 0.01 -> "1/2"
            abs(fraction - 0.67) < 0.02 -> "2/3"
            abs(fraction - 0.75) < 0.01 -> "3/4"
            true -> Float.round(fraction, 2) |> to_string()
          end

        if fraction < 0.05 do
          to_string(whole)
        else
          "#{whole} #{fraction_str}"
        end

      true ->
        Float.round(float_val, 2) |> to_string()
    end
  end

  defp format_quantity(quantity), do: to_string(quantity)

  defp render_nav(assigns) do
    ~H"""
    <nav class="mobile-nav bg-gray-900/95 backdrop-blur-lg border-t border-gray-800">
      <div class="max-w-2xl mx-auto px-4">
        <div class="flex items-center justify-around pt-2 pb-1">
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
          <a href="/groceries" class="flex flex-col items-center gap-1 text-purple-400 transition-colors">
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
              <path d="M3 1a1 1 0 000 2h1.22l.305 1.222a.997.997 0 00.01.042l1.358 5.43-.893.892C3.74 11.846 4.632 14 6.414 14H15a1 1 0 000-2H6.414l1-1H14a1 1 0 00.894-.553l3-6A1 1 0 0017 3H6.28l-.31-1.243A1 1 0 005 1H3zM16 16.5a1.5 1.5 0 11-3 0 1.5 1.5 0 013 0zM6.5 18a1.5 1.5 0 100-3 1.5 1.5 0 000 3z"/>
            </svg>
            <span class="text-xs font-medium">Groceries</span>
          </a>
          <%= live_redirect to: "/users/settings", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white transition-colors" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
            </svg>
            <span class="text-xs font-medium">Profile</span>
          <% end %>
        </div>
      </div>
    </nav>
    """
  end
end
