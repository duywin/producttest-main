
document.addEventListener('DOMContentLoaded', function () {
    let scrollPanel = document.getElementById('product-scroll-panel');
    let loadingSpinner = document.getElementById('loading-spinner');
    let currentPage = 1;
    let isLoading = false;
    let allProductsLoaded = false;

    scrollPanel.addEventListener('scroll', function () {
        let nearBottom = scrollPanel.scrollTop + scrollPanel.clientHeight >= scrollPanel.scrollHeight - 10;
        if (nearBottom && !isLoading && !allProductsLoaded) {
            isLoading = true;
            loadingSpinner.style.display = 'block';
            loadMoreProducts();
        }
    });

    function loadMoreProducts() {
        currentPage++;
        let queryParams = combineFormData(); // Assuming this function exists in another file

        fetch(`/shop?page=${currentPage}&${queryParams}`, {
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

                if (newProducts.trim()) {
                    document.getElementById('product-container').insertAdjacentHTML('beforeend', newProducts);
                } else {
                    allProductsLoaded = true;
                }
                loadingSpinner.style.display = 'none';
                isLoading = false;
            })
            .catch(error => {
                console.error('Error loading more products:', error);
                loadingSpinner.style.display = 'none';
                isLoading = false;
            });
    }
});
