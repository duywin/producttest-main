// app/assets/javascripts/promotion_merchandise_toggle.js

$(document).ready(function() {
    const products = window.productsData; // Use the products data from the view
    const categories = [...new Set(products.map(product => product.product_type))]; // Extract unique categories

    // Show the promotion form by default
    $('#promotion-form').show();
    $('#merchandise-form').hide();

    $('#toggle-promotion').on('click', function() {
        $('#promotion-form').show(); // Show the promotion form
        $('#merchandise-form').hide(); // Hide the merchandise form
    });

    $('#toggle-merchandise').on('click', function() {
        $('#merchandise-form').show(); // Show the merchandise form
        $('#promotion-form').hide(); // Hide the promotion form
    });

    $('#promotion-type').on('change', function() {
        const promotionType = $(this).val();
        const $applyField = $('#apply-field');

        $applyField.empty(); // Clear existing options

        if (promotionType === 'product' || promotionType === 'free_product') {
            // Populate with product IDs for product and free_product types
            products.forEach(product => {
                $applyField.append(new Option(`${product.name} (ID: ${product.id})`, product.id));
            });
            $('#apply-field-section').show(); // Show apply field for product types
        } else if (promotionType === 'category') {
            // Populate with product categories
            categories.forEach(category => {
                $applyField.append(new Option(category, category));
            });
            $('#apply-field-section').show(); // Show apply field for category types
        } else if (promotionType === 'cart') {
            // Hide apply field for cart promotion
            $('#apply-field-section').hide();
        }
    });

    $('#promotion-type').trigger('change'); // Trigger change event on page load to apply initial logic
});
