$ ->
# Initialize DataTable for Products table
  $('#products-table').DataTable
    paging: true
    pageLength: 10
    ordering: true
    search: false

  # Initialize DataTable for Promotions table
  $('#promotions-table').DataTable
    paging: true
    pageLength: 5
    ordering: true
    search: false

  # Initialize DataTable for Merchandise table
  $('#merchandise-table').DataTable
    paging: true
    pageLength: 5
    ordering: true
    search: false