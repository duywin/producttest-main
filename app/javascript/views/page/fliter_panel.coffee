combineFormData = ->
    searchInput = document.querySelector 'input[name="search"]'
    typeSelect = document.querySelector 'select[name="product_type"]'
    priceMinInput = document.querySelector 'input[name="price_min"]'
    priceMaxInput = document.querySelector 'input[name="price_max"]'

    queryParams = new URLSearchParams()

    if searchInput and searchInput.value
        queryParams.set 'search', searchInput.value
    if typeSelect and typeSelect.value
        queryParams.set 'product_type', typeSelect.value
    if priceMinInput and priceMinInput.value
        queryParams.set 'price_min', priceMinInput.value
    if priceMaxInput and priceMaxInput.value
        queryParams.set 'price_max', priceMaxInput.value

    queryParams.toString()

handleFilterFormSubmit = (event) ->
    event.preventDefault()

    combinedQueryParams = combineFormData()

    $.ajax
        url: "#{event.target.action}?#{combinedQueryParams}"
        method: 'GET'
        headers:
            'X-Requested-With': 'XMLHttpRequest'
        success: (html) ->
            parser = new DOMParser()
            doc = parser.parseFromString(html, 'text/html')
            newProducts = doc.getElementById('product-container').innerHTML
            document.getElementById('product-container').innerHTML = newProducts
        error: (jqXHR, textStatus, errorThrown) ->
            console.error 'Error:', textStatus, errorThrown

document.addEventListener 'DOMContentLoaded', ->
    $('#type-filter-form').on 'submit', handleFilterFormSubmit
    $('#price-filter-form').on 'submit', handleFilterFormSubmit
    $('#filter-form').on 'submit', handleFilterFormSubmit
