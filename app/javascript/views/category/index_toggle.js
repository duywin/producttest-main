$(document).ready(function() {
    $("#create-category-button").click(function() {
        $("#create-category-form").toggleClass("d-none");
    });

    $("#import-categories-button").click(function() {
        $("#import-categories-form").toggleClass("d-none");
    });
});