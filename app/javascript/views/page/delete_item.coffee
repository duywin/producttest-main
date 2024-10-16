$(document).ready ->
    $('.delete-btn').on 'click', ->
        itemId = $(this).data('id')

        $.ajax
            url: "/cart_items/#{itemId}"
            method: 'DELETE'
            headers:
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            success: (data) ->
                if data.success
                    $("[data-cart-item-id='#{itemId}']").remove()
                    updateTotalPrice() # Update total price after item removal
                else
                    alert data.message
