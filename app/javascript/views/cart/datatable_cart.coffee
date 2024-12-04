load_cart_datatable = () ->
  week = $('#selected_week').val()   # Retrieve selected week
  day = $('#selected_day').val()     # Retrieve selected day

  # Initialize or reload the DataTable with filters
  $('#carts-table').DataTable
    responsive: true
    paging: true
    searching: false
    ordering: true
    autoWidth: false
    processing: true
    destroy: true
    ajax:
      url: $('#api_cart_datatable').val()  # Path for API call
      dataType: "json"
      data:
        week: week
        day: day
      dataSrc: (json) -> json.data  # Properly bind data

    columns: [
      { data: 'username', width: '20%' }
      { data: 'total', width: '20%' }
      { data: 'address', width: '25%' }
      { data: 'status', width: '15%' }
      { data: 'actions', orderable: false, width: '20%' }
    ]
    lengthMenu: [5, 10, 25, 100]
    displayLength: 5
    language:
      lengthMenu: "_MENU_ per page"
      search: ''
      searchPlaceholder: 'Search by keywords'
      paginate:
        first: ''
        last: ''
        previous: ''
        next: ''

# Enable/disable days based on week selection
$('#week_selector').on 'change', (event) ->
  weekSelected = $(event.currentTarget).val()
  $('.weekday').toggleClass('disabled', !weekSelected)

  # Clear day selection if no week is selected
  if not weekSelected
    $('#selected_day').val('')  # Clear hidden day field
    $('.weekday').removeClass('active')

  load_cart_datatable()  # Reload data table with new week selection

# Update active day and reload DataTable when a day is selected
$('.weekday').on 'click', (event) ->
  return if $(event.currentTarget).hasClass('disabled')  # Skip if disabled
  $(event.currentTarget).addClass('active').siblings().removeClass('active')
  $('#selected_day').val($(event.currentTarget).data('day'))  # Update hidden day field

  load_cart_datatable()  # Reload data table with selected day

# Initial load: call `load_cart_datatable` once on page load
$(document).ready ->
  load_cart_datatable()
