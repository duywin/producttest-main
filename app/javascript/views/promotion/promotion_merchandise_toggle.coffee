$ ->
# Access the data from the window.promotionData object
    products = window.promotionData.products
    categories = window.promotionData.categories

    $('#promotion-form').show()
    $('#merchandise-form').hide()

    # Toggle forms visibility
    $('#toggle-promotion').on 'click', ->
        $('#promotion-form').show()
        $('#merchandise-form').hide()

    $('#toggle-merchandise').on 'click', ->
        $('#merchandise-form').show()
        $('#promotion-form').hide()

    # Handle promotion type changes
    $('#promotion-type').on 'change', ->
        promotionType = $(this).val()
        $applyField = $('#apply-field')
        $applyField.empty()  # Clear previous options

        # Populate the apply field based on the selected promotion type
        if promotionType == 'product'
            products.forEach (product) ->
                $applyField.append(new Option("#{product.name} (ID: #{product.id})", product.id))
            $('#apply-field-section').show()

        else if promotionType == 'category'
            categories.forEach (category) ->
                $applyField.append(new Option(category, category))
            $('#apply-field-section').show()

        else if promotionType == 'cart'
            $('#apply-field-section').hide()  # Hide apply field section for cart promotions

    # Trigger change on page load to initialize the field correctly
    $('#promotion-type').trigger 'change'
