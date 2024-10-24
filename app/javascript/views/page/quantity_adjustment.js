$(document).ready(function () {
    $('.quantity button').on('click', function () {
        const action = $(this).data('action');
        const itemId = $(this).data('id');
        const quantityInput = $(`input[data-id="${itemId}"]`);
        let quantity = parseInt(quantityInput.val());
        const stock = parseInt($(this).closest('.item').data('stock'));

        if (action === 'increment') {
            if (quantity < stock) {
                quantity++;
            } else {
                alert('Exceeding stock amount, please wait for restock');
                return; // Exit if exceeding stock
            }
        } else if (action === 'decrement') {
            if (quantity > 1) {
                quantity--;
            } else {
                $(`.delete-btn[data-id="${itemId}"]`).click();
                return; // Exit since delete will handle removal
            }
        }

        // Update the cart item quantity via AJAX
        $.ajax({
            url: `/cart_items/${itemId}`,
            method: 'PATCH',
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            data: JSON.stringify({ quantity: quantity }),
            contentType: 'application/json',
            success: function (data) {
                if (data.success) {
                    quantityInput.val(data.new_quantity);
                    updateTotalPrice(); // Update total price logic
                } else {
                    alert(data.message);
                }
            }
        });
    });
});
