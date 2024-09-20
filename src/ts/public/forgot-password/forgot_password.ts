import Modal from 'bootstrap/js/dist/modal';
import { BasicAlert } from '@components/alerts';

document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('emailForm') as HTMLFormElement;
    const alert = new BasicAlert('formAlerts');

    form.addEventListener('submit', async (event) => {
        event.preventDefault();

        if (!form.checkValidity()) {
            event.stopPropagation();
            form.classList.add('was-validated');
            return;
        }

        const formData = new FormData(form);
        const data = {
            email: formData.get('email'),
        };

        try {
            const response = await fetch('/api/auth/forgot-password', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data),
            });
            const res = await response.json();
            if (!response.ok) {
                console.error(res);
                throw new Error(res.error || 'An error occurred');
            }

            const modalElement = document.getElementById('statusSuccessModal')!;
            const successModalTxt = document.getElementById('successModalText')!;
            const successModal = new Modal(modalElement);
            successModalTxt.textContent = res.message;

            modalElement.addEventListener('hidden.bs.modal', function () {
                window.location.href = '/auth/login';
            });
            successModal.show();
        } catch (_e) {
            alert.displayMessage({
                message: 'An error occurred. Please try again.',
                type: 'danger',
            });
        }
    });
});
