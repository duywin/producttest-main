updateTotalPrice = (discount = 0) ->
    total = 0
    $('.item').each ->
        quantity = parseInt $(this).find('.quantity-input').val()
        price = parseFloat $(this).find('.total-price').text().replace /[^0-9.-]+/g, ""
        total += quantity * price

    total -= total * (discount / 100)
    $('#cart-total').text new Intl.NumberFormat('en-US',
        style: 'currency'
        currency: 'USD'
    ).format(total)

updateItemPrices = (updatedPrices) ->
    $('.item').each ->
        itemId = $(this).data('cart-item-id')
        itemPrices = updatedPrices[itemId]

        if itemPrices
            oldPrice = itemPrices.old_price
            newPrice = itemPrices.new_price

            # Populate the old price (with strikethrough) and new price for the item
            $(this).find('.old-price').text new Intl.NumberFormat('en-US',
                style: 'currency'
                currency: 'USD'
            ).format(oldPrice).show() # Show the old price

            $(this).find('.new-price').text new Intl.NumberFormat('en-US',
                style: 'currency'
                currency: 'USD'
            ).format(newPrice)

    updateTotalPrice() # Recalculate the total price
