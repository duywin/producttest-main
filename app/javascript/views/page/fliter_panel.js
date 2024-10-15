// filter.js

function combineFormData() {
    const searchInput = document.querySelector('input[name="search"]');
    const typeSelect = document.querySelector('select[name="product_type"]');
    const priceMinInput = document.querySelector('input[name="price_min"]');
    const priceMaxInput = document.querySelector('input[name="price_max"]');

    let queryParams = new URLSearchParams();

    if (searchInput && searchInput.value) {
        queryParams.set('search', searchInput.value);
    }
    if (typeSelect && typeSelect.value) {
        queryParams.set('product_type', typeSelect.value);
    }
    if (priceMinInput && priceMinInput.value) {
        queryParams.set('price_min', priceMinInput.value);
    }
    if (priceMaxInput && priceMaxInput.value) {
        queryParams.set('price_max', priceMaxInput.value);
    }

    return queryParams.toString();
}

function handleFilterFormSubmit(event) {
    event.preventDefault();

    const combinedQueryParams = combineFormData();

    fetch(`${event.target.action}?${combinedQueryParams}`, {
        method: 'GET',
        headers: {
            'X-Requested-With': 'XMLHttpRequest'
        }
    })
        .then(response => response.text())
        .then(html => {
            const parser = new DOMParser();
            const doc = parser.parseFromString(html, 'text/html');
            const newProducts = doc.getElementById('product-container').innerHTML;
            document.getElementById('product-container').innerHTML = newProducts;
        })
        .catch(error => console.error('Error:', error));
}

document.addEventListener('DOMContentLoaded', function () {
    document.getElementById('type-filter-form').addEventListener('submit', handleFilterFormSubmit);
    document.getElementById('price-filter-form').addEventListener('submit', handleFilterFormSubmit);
    document.getElementById('filter-form').addEventListener('submit', handleFilterFormSubmit);
});
