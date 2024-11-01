$ ->
  load_cart_datatable = () ->
    week = $('#selected_week').val() # Retrieve from hidden field
    day = $('#selected_day').val()    # Retrieve from hidden field

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
        url: $('#api_cart_datatable').val()
        dataType: "json"
        data:
          week: week
          day: day
        dataSrc: (json) -> json.data

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

  # Enable or disable day selection based on week selection
  $('#week_selector').on 'change', (event) ->
    weekSelected = $(event.currentTarget).val()
    event.preventDefault()

    # Enable or disable day buttons
    $('.weekday').toggleClass('disabled', !weekSelected)

    # Reset day selection if no week is selected
    if not weekSelected
      $('.weekday').removeClass('active')
      $('#selected_day').val('') # Clear hidden day field

    load_cart_datatable()

  # Update active day and reload DataTable when a day is selected
  $('.weekday').on 'click', (event) ->
    return if $(event.currentTarget).hasClass('disabled') # Skip if disabled
    event.preventDefault()

    # Update active day styling
    $(event.currentTarget).addClass('active').siblings().removeClass('active')

    # Trigger table reload with selected week and day
    load_cart_datatable()

  load_cart_datatable() # Initial load on page ready
