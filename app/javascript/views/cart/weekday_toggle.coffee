document.addEventListener 'DOMContentLoaded', ->

weekSelectors = document.querySelectorAll('.week-selector')
weekdayLinks = document.querySelectorAll('.weekday')

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

# Disable weekdays initially if no week is selected
activeWeek = document.querySelector('.week-selector.active')
toggleWeekdayLinks(!!activeWeek)