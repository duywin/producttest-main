document.addEventListener 'DOMContentLoaded', ->
    scrollPanel = document.getElementById 'product-scroll-panel'
    loadingSpinner = document.getElementById 'loading-spinner'
    currentPage = 1
    isLoading = false
    allProductsLoaded = false
    totalProducts = 100  # Replace with actual total count from the server

    scrollPanel.addEventListener 'scroll', ->
        nearBottom = scrollPanel.scrollTop + scrollPanel.clientHeight >= scrollPanel.scrollHeight - 10
        if nearBottom and not isLoading and not allProductsLoaded
            isLoading = true
            loadingSpinner.style.display = 'block'
            loadMoreProducts()

    loadMoreProducts = ->
        currentPage++
        queryParams = combineFormData() # Ensure this function is defined in another file

        $.ajax
            url: "/shop?page=#{currentPage}&#{queryParams}"
            method: 'GET'
            headers:
                'X-Requested-With': 'XMLHttpRequest'
            success: (html) ->
                parser = new DOMParser()
                doc = parser.parseFromString(html, 'text/html')
                newProducts = doc.getElementById('product-container').innerHTML

                if newProducts.trim()
                    document.getElementById('product-container').insertAdjacentHTML 'beforeend', newProducts
                else
                    allProductsLoaded = true  # No more products to load

                loadingSpinner.style.display = 'none'
                isLoading = false

                # Check if we reached the maximum number of products
                if currentPage * 6 >= totalProducts  # Assuming 6 products per page
                    allProductsLoaded = true  # Disable further loading
            error: (jqXHR, textStatus, errorThrown) ->
                console.error 'Error loading more products:', textStatus, errorThrown
                loadingSpinner.style.display = 'none'
                isLoading = false

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
