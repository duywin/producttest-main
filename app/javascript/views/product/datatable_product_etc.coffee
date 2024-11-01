$ ->
  load_product_datatable = () ->
    search_field = $('#product_filter_form').find('input[name="query"]').val()

    $('#products-table').DataTable
      responsive: true
      paging: true
      searching: false
      ordering: true
      autoWidth: false
      processing: true
      destroy: true
      ajax:
        url: $('#api_product_datatable').val()
        dataType: "json"
        data:
          query: search_field
        dataSrc: (json) -> json.data

      columns: [
        { data: 'name', width: '45%' }
        { data: 'prices', width: '20%' }
        { data: 'product_type', width: '20%' }
        { data: 'actions', orderable: false, width: '25%' }
      ]

      lengthMenu: [10, 25, 50, 100]
      displayLength: 10

  load_promotion_datatable = () ->
    $('#promotions-table').DataTable
      responsive: true
      paging: true
      searching: false
      ordering: true
      autoWidth: false
      processing: true
      destroy: true
      ajax:
        url: $('#api_promotion_datatable').val()
        dataType: "json"
        dataSrc: (json) -> json.data

      columns: [
        { data: 'promote_code', width: '25%' }
        { data: 'promotion_type', width: '25%' }
        { data: 'apply_field', width: '25%' }
        { data: 'end_date', width: '15%' }
        { data: 'min_quantity', width: '10%' }
        { data: 'actions', orderable: false, width: '10%' }
      ]

      lengthMenu: [5, 10, 25, 100]
      displayLength: 5

  load_merchandise_datatable = () ->
    $('#merchandise-table').DataTable
      responsive: true
      paging: true
      searching: false
      ordering: true
      autoWidth: false
      processing: true
      destroy: true
      ajax:
        url: $('#api_merchandise_datatable').val()
        dataType: "json"
        dataSrc: (json) -> json.data

      columns: [
        { data: 'product_id', width: '40%' }
        { data: 'cut_off_value', width: '40%' }
        { data: 'promotion_end', width: '15%' }
        { data: 'actions', orderable: false, width: '5%' }
      ]

      lengthMenu: [5, 10, 25, 100]
      displayLength: 5

  deleteProduct = (id) ->
    $.ajax
      url: "/products/#{id}"
      type: "DELETE"
      dataType: "json"
      success: (data) ->
        load_product_datatable()
      error: (xhr, status, error) ->
        alert("An error occurred while deleting the product.")

  deletePromotion = (id) ->
    $.ajax
      url: "/promotions/#{id}"
      type: "DELETE"
      dataType: "json"
      success: (data) ->
        load_promotion_datatable()
      error: (xhr, status, error) ->
        alert("An error occurred while deleting the promotion.")

  deleteMerchandise = (id) ->
    $.ajax
      url: "/merchandises/#{id}"
      type: "DELETE"
      dataType: "json"
      success: (data) ->
        load_merchandise_datatable()
      error: (xhr, status, error) ->
        alert("An error occurred while deleting the merchandise.")

  # Event listener for product filter form submission
  $('#product_filter_form').on 'submit', (event) ->
    event.preventDefault()
    load_product_datatable()

  # Initialize all DataTables
  load_product_datatable()
  load_promotion_datatable()
  load_merchandise_datatable()
