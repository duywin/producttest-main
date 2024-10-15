$(document).ready(function () {
    $('#checkout-btn').on('click', function () {
        const cartId = $('div[data-cart-id]').data('cart-id');

        $.ajax({
            url: `/carts/${cartId}/checkout`,
            method: 'PATCH',
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function (response) {
                if (response.success) {
                    alert('Checkout completed successfully.'); // Alert user on success
                    // Update hidden form with necessary cart data, then submit
                    $('#redirect-form input[name="cart_id"]').val(cartId);
                    $('#redirect-form').submit(); // Submit the form to redirect
                } else {
                    alert('Error: ' + response.message); // Show error message from the server
                }
            },
            error: function (xhr, status, error) {
                console.error('Error during checkout', error);
                alert('An error occurred during checkout. Please try again.');
            }
        });
    });
});