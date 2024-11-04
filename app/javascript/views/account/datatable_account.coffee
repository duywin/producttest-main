$ ->
  load_datatable = () ->
    search_field = $('#username_cont').val()
    selected_time = $('#created_at_filter').find(':selected').val()

    $('#accounts-table').DataTable
      responsive: true
      paging: true
      searching: false
      ordering: true
      autoWidth: false
      processing: true
      destroy: true
      ajax:
        url: $('#api_account_datatable').val()
        dataType: "json"
        data:
          username_cont: search_field
          created_at_filter: selected_time
        dataSrc: (json) -> json.data

      columns: [
        { data: 'username', width: '45%', className: 'number' }
        { data: 'email', width: '45%', className: 'number' }
        { data: 'status', width: '10%', className: 'number' }
        { data: 'actions', orderable: false, width: '10%' }
      ]

      lengthMenu: [10, 25, 50, 100]
      displayLength: 10

      language:
        lengthMenu: "_MENU_ per page"
        search: ''
        searchPlaceholder: 'Search by keywords'
        paginate:
          first: ''
          last: ''
          previous: ''
          next: ''

  $('#filter_form').on 'submit', (event) ->
    event.preventDefault()
    load_datatable()

  load_datatable()

# Get the CSRF token from the meta tag
csrfToken = $('meta[name="csrf-token"]').attr('content')

$(document).on 'click', '.delete-account-btn', (e) ->
  accountId = $(e.target).data('account-id')  # Get the account ID from the button

  if confirm('Are you sure you want to delete this account?')
    $.ajax
      url: "/accounts/#{accountId}"  # URL to the delete action
      type: 'DELETE'
      headers:
        'X-CSRF-Token': csrfToken  # Include the CSRF token in the headers
      success: ->
        $('#accounts-table').DataTable().ajax.reload()  # Refresh the accounts table or handle UI update
      error: (xhr, status, error) ->
        alert("An error occurred while deleting the account: #{xhr.responseText}")  # Handle any errors

