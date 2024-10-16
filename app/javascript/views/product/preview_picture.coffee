$ ->
    $('#show_picture').on 'click', ->
        pictureUrl = $('#picture_url').val()
        $container = $('#picture_container')

        # Clear previous content
        $container.empty()

        if pictureUrl
            img = $('<img>',
                src: pictureUrl
                alt: 'Product Picture'
                class: 'img-fluid'
                css:
                    'max-width': '200px'
                    'max-height': '200px'
            )
            $container.append img
        else
            $container.text 'No picture available'
