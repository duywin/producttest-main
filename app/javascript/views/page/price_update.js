function updateTotalPrice(discount = 0) {
    let total = 0;
    $('.item').each(function () {
        const quantity = parseInt($(this).find('.quantity-input').val());
        const price = parseFloat($(this).find('.total-price').text().replace(/[^0-9.-]+/g, ""));
        total += quantity * price;
    });
    total = total - (total * (discount / 100));
    $('#cart-total').text(new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
    }).format(total));
}

function updateItemPrices(updatedPrices) {
    $('.item').each(function () {
        const itemId = $(this).data('cart-item-id');
        const itemPrices = updatedPrices[itemId];

        if (itemPrices) {
            const oldPrice = itemPrices.old_price;
            const newPrice = itemPrices.new_price;

            // Populate the old price (with strikethrough) and new price for the item
            $(this).find('.old-price').text(new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: 'USD'
            }).format(oldPrice)).show(); // Show the old price

            $(this).find('.new-price').text(new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: 'USD'
            }).format(newPrice));
        }
    });
    updateTotalPrice(); // Recalculate the total price
}
