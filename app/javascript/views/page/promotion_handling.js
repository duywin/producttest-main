$(document).ready(function () {
    $('#apply-promo-btn').on('click', function () {
        const promoCode = $('#promotion-code').val();
        const cartId = $('div[data-cart-id]').data('cart-id');
        const csrfToken = $('meta[name="csrf-token"]').attr('content');

        // Check if the promotion code is for the entire cart or for individual items
        $.ajax({
            url: `/promotions/check_type`,
            method: 'POST',
            headers: {
                'X-CSRF-Token': csrfToken
            },
            data: {promote_code: promoCode},
            success: function (response) {
                if (response.success) {
                    if (response.promotion_type === 'cart') {
                        applyCartPromotion(promoCode, cartId, csrfToken);
                    } else {
                        applyItemPromotion(promoCode, cartId, csrfToken);
                    }
                } else {
                    alert('Invalid promotion code');
                }
            },
            error: function (xhr, status, error) {
                alert('Error verifying promotion: ' + error);
            }
        });
    });
});

function applyCartPromotion(promoCode, cartId, csrfToken) {
    $.ajax({
        url: `/carts/${cartId}/apply_cart_promotion`,
        method: 'POST',
        headers: {
            'X-CSRF-Token': csrfToken
        },
        data: {promote_code: promoCode, cart_id: cartId},
        success: function (response) {
            if (response.success) {
                const newTotal = response.new_total;
                const oldTotal = $('#new-cart-total').text().replace(/[^0-9.-]+/g, "");

                // Update totals in UI
                $('#old-cart-total').text(new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: 'USD'
                }).format(oldTotal));
                $('#new-cart-total').text(new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: 'USD'
                }).format(newTotal));
                $('#discount-line').show();
                document.getElementById('discount-message').innerText = response.message;

                alert('Cart promotion applied successfully');
            } else {
                alert(response.message);
            }
        },
        error: function (xhr, status, error) {
            alert('Error applying cart promotion: ' + error);
        }
    });
}

function applyItemPromotion(promoCode, cartId, csrfToken) {
    $.ajax({
        url: `/cart_items/apply_promotion`,
        method: 'POST',
        headers: {
            'X-CSRF-Token': csrfToken
        },
        data: {promote_code: promoCode, cart_id: cartId},
        success: function (response) {
            if (response.success) {
                document.getElementById('discount-message').innerText = response.message;
                document.getElementById('discount-line').style.display = 'block';
                alert('Promotion applied successfully: ' + response.message);

                // Pass the updated prices (with old and new prices) to updateItemPrices
                updateItemPrices(response.updated_prices);
            } else {
                alert('Failed to apply promotion: ' + response.message);
            }
        },
        error: function (xhr, status, error) {
            alert('Error applying promotion: ' + xhr.responseJSON.message || error);
        }
    });
}
