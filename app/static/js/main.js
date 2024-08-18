function showErrorModal(message, title = 'An error occurred') {
    const modalElement = document.getElementById('statusErrorsModal');
    if (!modalElement || modalElement.classList.contains('show')) {
        return;
    }
    const errorModal = new bootstrap.Modal(modalElement);
    console.log

    document.getElementById('errorModalDescription').innerText = message;
    document.getElementById('errorModalTitleError').innerText = title;

    errorModal.show();
}

function showSuccessModal() {
    const modalElement = document.getElementById('statusSuccessModal');
    if (!modalElement || modalElement.classList.contains('show')) {
        return;
    }
    const successModal = new bootstrap.Modal(modalElement);

    successModal.show();
}