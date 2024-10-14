// app/assets/javascript/views/promotion/toggle_forms_jquery.js
$(document).ready(function() {
    function toggleForms(formType) {
        if (formType === 'create') {
            $('#createForm').show();
            $('#importForm').hide();
        } else {
            $('#createForm').hide();
            $('#importForm').show();
        }
    }

    // Bind click events to buttons
    $('#createBtn').on('click', function() {
        toggleForms('create');
    });

    $('#importBtn').on('click', function() {
        toggleForms('import');
    });
});
