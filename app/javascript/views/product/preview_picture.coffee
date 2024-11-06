$ ->
# Toggle forms
    $('#show_url_picture').on 'click', ->
        $('#url_picture_form').show()
        $('#file_picture_form').hide()
        $('#picture_container').empty()  # Clear the preview when switching

    $('#show_file_picture').on 'click', ->
        $('#file_picture_form').show()
        $('#url_picture_form').hide()
        $('#picture_container').empty()  # Clear the preview when switching

    # Show the image preview for URL input
    $('#show_url_image').on 'click', ->
        pictureUrl = $('#picture_url').val()
        $container = $('#picture_container')

        $container.empty()

        if pictureUrl
            img = $('<img>',
                src: pictureUrl,
                alt: 'Product Picture',
                class: 'img-fluid',
                css:
                    'max-width': '200px',
                    'max-height': '200px'
            )
            $container.append img
        else
            $container.text 'No picture available'

    # Show the image preview for file input (using CarrierWave)
    $('#show_file_image').on 'click', ->
        pictureFile = $('#picture_file')[0].files[0] # Get the file from input
        $container = $('#picture_container')

        $container.empty()

        if pictureFile
            reader = new FileReader()
            reader.onload = (e) ->
                img = $('<img>',
                    src: e.target.result,
                    alt: 'Product Picture',
                    class: 'img-fluid',
                    css:
                        'max-width': '200px',
                        'max-height': '200px'
                )
                $container.append img
            reader.readAsDataURL(pictureFile)
        else
            $container.text 'No picture available'
