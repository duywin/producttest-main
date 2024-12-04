document.addEventListener 'DOMContentLoaded', ->

  weekSelectors = document.querySelectorAll('.week-selector')
  weekdayLinks = document.querySelectorAll('.weekday')
  sortOrderSelectors = document.querySelectorAll('.sort-order') # New selector for sort options

  # Function to toggle weekday link activation
  toggleWeekdayLinks = (enable) ->
    weekdayLinks.forEach (link) ->
      if enable
        link.classList.remove('disabled')
      else
        link.classList.add('disabled')

  # Add event listeners to week selectors
  weekSelectors.forEach (weekSelector) ->
    weekSelector.addEventListener 'click', ->
      isActive = @classList.contains('active')
      toggleWeekdayLinks(isActive)

  # Handle sort order change
  sortOrderSelectors.forEach (sortOrderSelector) ->
    sortOrderSelector.addEventListener 'change', ->
      selectedOrder = @value
      fetchSortedData(selectedOrder) # Function to fetch data based on the selected sort order

  # Function to fetch data with sorting applied
  fetchSortedData = (sortOrder) ->
    params =
      week: document.querySelector('.week-selector.active')?.dataset.week
      day: document.querySelector('.weekday.active')?.dataset.day
      sort_order: sortOrder

    fetch('/path/to/endpoint', {
      method: 'POST'
      headers: { 'Content-Type': 'application/json' }
      body: JSON.stringify(params)
    }).then (response) ->
      response.json()
      .then (data) ->
      updateUI(data) # Update the UI with the fetched data

  # Disable weekdays initially if no week is selected
  activeWeek = document.querySelector('.week-selector.active')
  toggleWeekdayLinks(!!activeWeek)
