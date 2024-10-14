
$(document).ready(function() {
    $('#show_picture').on('click', function() {
        var pictureUrl = $('#picture_url').val();
        var $container = $('#picture_container');

        // Clear previous content
        $container.empty();

        if (pictureUrl) {
            var img = $('<img>', {
                src: pictureUrl,
                alt: 'Product Picture',
                class: 'img-fluid',
                css: { 'max-width': '200px', 'max-height': '200px' }
            });
            $container.append(img);
        } else {
            $container.text('No picture available');
        }
    });
});
