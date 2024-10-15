$(document).ready(function () {
    $('.delete-btn').on('click', function () {
        const itemId = $(this).data('id');

        $.ajax({
            url: `/cart_items/${itemId}`,
            method: 'DELETE',
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            success: function (data) {
                if (data.success) {
                    $(`[data-cart-item-id="${itemId}"]`).remove();
                    updateTotalPrice(); // Update total price after item removal
                } else {
                    alert(data.message);
                }
            }
        });
    });
});
