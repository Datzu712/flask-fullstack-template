const forms = document.querySelectorAll('.needs-validation') as NodeListOf<HTMLFormElement>;
Array.prototype.slice.call(forms).forEach(function (form: HTMLFormElement) {
    form.addEventListener(
        'submit',
        function (event) {
            if (!form.checkValidity()) {
                event.preventDefault();
                event.stopPropagation();
            }
            form.classList.add('was-validated');
        },
        false,
    );
});
