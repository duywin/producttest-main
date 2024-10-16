$ ->
    toggleForms = (formType) ->
        if formType == 'create'
            $('#createForm').show()
            $('#importForm').hide()
        else
            $('#createForm').hide()
            $('#importForm').show()

    # Bind click events to buttons
    $('#createBtn').on 'click', ->
        toggleForms 'create'

    $('#importBtn').on 'click', ->
        toggleForms 'import'
