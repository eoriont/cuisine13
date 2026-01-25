defmodule Cuisine13Web.CalendarFeedController do
  use Cuisine13Web, :controller

  alias Cuisine13.{Households, Planning}

  @doc """
  Serves an iCal (.ics) feed for a household's meal calendar.
  The token in the URL authenticates access without requiring login.
  """
  def show(conn, %{"token" => token}) do
    case Households.get_household_by_feed_token(token) do
      nil ->
        conn
        |> put_status(:not_found)
        |> text("Calendar feed not found")

      household ->
        # Get meals for the next 60 days and past 30 days
        today = Date.utc_today()
        start_date = Date.add(today, -30)
        end_date = Date.add(today, 60)

        meals = Planning.list_planned_meals(household.id, start_date, end_date)
        ics_content = generate_ics(household, meals)

        conn
        |> put_resp_content_type("text/calendar")
        |> put_resp_header("content-disposition", "inline; filename=\"cuisine13-meals.ics\"")
        |> text(ics_content)
    end
  end

  defp generate_ics(household, meals) do
    events = Enum.map(meals, &meal_to_vevent/1) |> Enum.join("")

    """
    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//Cuisine13//Meal Planner//EN
    CALSCALE:GREGORIAN
    METHOD:PUBLISH
    X-WR-CALNAME:#{escape_text(household.name)} Meals
    X-WR-TIMEZONE:UTC
    #{events}END:VCALENDAR
    """
  end

  defp meal_to_vevent(meal) do
    # Meal times in the household's assumed timezone (we'll use local time)
    {start_hour, end_hour} = meal_time_range(meal.meal_type)

    # Create datetime for the meal
    start_dt = format_datetime(meal.scheduled_date, start_hour)
    end_dt = format_datetime(meal.scheduled_date, end_hour)

    # Generate unique ID based on meal id and updated timestamp
    uid = "meal-#{meal.id}@cuisine13.app"
    dtstamp = format_timestamp(meal.updated_at || meal.inserted_at)

    recipe_title = if meal.recipe, do: meal.recipe.title, else: "Meal"
    meal_label = String.capitalize(meal.meal_type)
    summary = "#{meal_label}: #{recipe_title}"

    description_parts = [
      if(meal.servings, do: "Servings: #{meal.servings}", else: nil),
      if(meal.notes && meal.notes != "", do: "Notes: #{meal.notes}", else: nil),
      if(meal.is_leftover, do: "(Leftover)", else: nil)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\\n")

    """
    BEGIN:VEVENT
    UID:#{uid}
    DTSTAMP:#{dtstamp}
    DTSTART:#{start_dt}
    DTEND:#{end_dt}
    SUMMARY:#{escape_text(summary)}
    DESCRIPTION:#{escape_text(description_parts)}
    CATEGORIES:#{meal_label}
    END:VEVENT
    """
  end

  defp meal_time_range("breakfast"), do: {8, 9}
  defp meal_time_range("lunch"), do: {12, 13}
  defp meal_time_range("dinner"), do: {18, 19}
  defp meal_time_range("snack"), do: {15, 16}
  defp meal_time_range(_), do: {12, 13}

  defp format_datetime(date, hour) do
    # Format as YYYYMMDDTHHMMSS (local time, no timezone)
    date_str = Date.to_iso8601(date) |> String.replace("-", "")
    "#{date_str}T#{String.pad_leading(Integer.to_string(hour), 2, "0")}0000"
  end

  defp format_timestamp(datetime) do
    datetime
    |> NaiveDateTime.to_iso8601()
    |> String.replace(["-", ":"], "")
    |> String.split(".")
    |> hd()
    |> Kernel.<>("Z")
  end

  defp escape_text(nil), do: ""

  defp escape_text(text) do
    text
    |> String.replace("\\", "\\\\")
    |> String.replace(",", "\\,")
    |> String.replace(";", "\\;")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "")
  end
end
