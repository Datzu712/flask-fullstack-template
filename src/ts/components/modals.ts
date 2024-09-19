import * as bootstrap from 'bootstrap';

export function showErrorModal(message: string, title: string = 'An error occurred'): void {
    const modalElement = document.getElementById('statusErrorsModal');
    if (!modalElement || modalElement.classList.contains('show')) {
        console.debug('Error modal already shown');
        return;
    }
    const errorModal = bootstrap.Modal.getInstance(modalElement) || new bootstrap.Modal(modalElement);

    const errorModalDescription = document.getElementById('errorModalDescription');
    const errorModalTitleError = document.getElementById('errorModalTitleError');

    if (errorModalDescription && errorModalTitleError) {
        errorModalDescription.innerText = message;
        errorModalTitleError.innerText = title;
        errorModal.show();
    } else {
        console.error('Error modal elements not found');
    }
}

export function showSuccessModal(message: string): void {
    const modalElement = document.getElementById('statusSuccessModal');
    if (!modalElement || modalElement.classList.contains('show')) {
        return;
    }
    const successModalTxt = document.getElementById('successModalTxt');
    if (successModalTxt) {
        successModalTxt.innerText = message;
        const successModal = new bootstrap.Modal(modalElement);
        successModal.show();
    } else {
        console.error('Success modal text element not found');
    }
}

interface QuestionOptions {
    text: string;
    title?: string;
    confirmButtonText?: string;
    confirmButtonColor?: string;
    cancelButtonText?: string;
    cancelButtonColor?: string;
    afterConfirm: () => void;
}
/**
 * Creates a confirmation modal with customizable options.
 *
 * @param { Object } options - The options for the confirmation modal.
 * @param { string } options.text - The text to display in the modal.
 * @param { string } [options.tittle] - The title of the modal. Defaults to '¿Está seguro de realizar esta acción?'.
 * @param { string } [options.confirmButtonText] - The text to display on the confirm button. Defaults to 'Sí, estoy seguro'.
 * @param { string } [options.confirmButtonColor] - The color of the confirm button. Defaults to 'primary'.
 * @param { string } [options.cancelButtonText] - The text to display on the cancel button. Defaults to 'Cancelar'.
 * @param { string } [options.cancelButtonColor] - The color of the cancel button. Defaults to 'secondary'.
 * @param { Function } options.afterConfirm - The function to execute after the confirm button is clicked.
 */
export function createQuestion(options: QuestionOptions): void {
    if (!options.text) {
        console.error('Text is required');
        return;
    }
    if (!options.afterConfirm) {
        console.error('Confirm function is required');
        return;
    }

    const confirmModalText = document.getElementById('confirmModalText');
    const confirmModalTitle = document.getElementById('confirmModalTitle');
    const confirmButton = document.getElementById('confirmModalButton');
    const cancelButton = document.getElementById('cancelModalButton');

    if (confirmModalText && confirmModalTitle && confirmButton && cancelButton) {
        confirmModalText.textContent = options.text;
        confirmModalTitle.textContent = options.title || '¿Está seguro de realizar esta acción?';

        confirmButton.textContent = options.confirmButtonText || 'Sí, estoy seguro';
        confirmButton.className = 'btn btn-' + (options.confirmButtonColor || 'primary');

        cancelButton.textContent = options.cancelButtonText || 'Cancelar';
        cancelButton.className = 'btn btn-' + (options.cancelButtonColor || 'secondary');

        const confirmFn = function () {
            options.afterConfirm();
            const confirmModal = bootstrap.Modal.getInstance(document.getElementById('confirmModal')!);
            if (confirmModal) {
                confirmModal.hide();
            }
        };

        confirmButton.addEventListener('click', confirmFn, { once: true });

        const element = document.getElementById('confirmModal');
        if (element) {
            const confirmModal = new bootstrap.Modal(element);
            confirmModal.show();

            element.addEventListener(
                'hidden.bs.modal',
                function () {
                    confirmButton.removeEventListener('click', confirmFn);
                },
                { once: true },
            );
        } else {
            console.error('Confirm modal element not found');
        }
    } else {
        console.error('Confirm modal elements not found');
    }
}
