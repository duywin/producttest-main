$(document).ready(function() {
    // Cache jQuery selectors
    const $accountDetails = $('#account-details');
    const $accountEditForm = $('#account-edit-form');
    const $deliveryHistoryContainer = $('#delivery-history-container');

    function toggleView(showAccount, showEdit, showDelivery) {
        $accountDetails.toggle(showAccount);
        $accountEditForm.toggle(showEdit);
        $deliveryHistoryContainer.toggle(showDelivery);
    }

    $('#show-account-management').click(function() {
        toggleView(true, false, false);
    });

    $('#show-delivery-history').click(function() {
        toggleView(false, false, true);
    });

    $('#edit-button').click(function() {
        toggleView(false, true, false);
    });
});
