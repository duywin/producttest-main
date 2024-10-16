$ ->
# Cache jQuery selectors
    $accountDetails = $('#account-details')
    $accountEditForm = $('#account-edit-form')
    $deliveryHistoryContainer = $('#delivery-history-container')

    toggleView = (showAccount, showEdit, showDelivery) ->
        $accountDetails.toggle showAccount
        $accountEditForm.toggle showEdit
        $deliveryHistoryContainer.toggle showDelivery

    $('#show-account-management').click ->
        toggleView true, false, false

    $('#show-delivery-history').click ->
        toggleView false, false, true

    $('#edit-button').click ->
        toggleView false, true, false
