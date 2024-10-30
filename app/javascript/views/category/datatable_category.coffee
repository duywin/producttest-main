$ ->
  $('#categories-table').DataTable
    ajax:
      url: '/categories.json'
      dataSrc: 'data'
    columns: [
      { data: 'name', title: 'Name' }
      { data: 'total', title: 'Total' }
      {
        data: 'id'
        title: 'Actions'
        render: (data) ->
# Generate HTML similar to the button_to helper in Haml
          "<form action='/categories/#{data}' method='post' style='display: inline;'>
            <input type='hidden' name='_method' value='delete' />
            <input type='hidden' name='authenticity_token' value='#{$('meta[name=csrf-token]').attr('content')}' />
            <button type='submit' style='background: none; border: none; color: red; cursor: pointer; font-size: 20px;' data-confirm='Are you sure?'>
              ❌
            </button>
          </form>"
      }
    ]
    paging: true
    ordering: true
    searching: true
    info: true

$(document).on 'click', '.delete-category-btn', (e) ->
  categoryId = $(e.target).data('category-id')

  if confirm('Are you sure you want to delete this category?')
    $.ajax
      url: "/categories/#{categoryId}"
      type: 'DELETE'
      success: ->
        $('#categories-table').DataTable().ajax.reload()
