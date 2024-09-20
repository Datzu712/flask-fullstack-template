import Modal from 'bootstrap/js/dist/modal';
import { BasicAlert } from '@components/alerts';

document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('resetPasswordForm') as HTMLFormElement;
    const successMessage = document.getElementById('success-message')!;

    const alert = new BasicAlert('formAlerts');

    const parts = window.location.pathname.split('/');
    const token = parts[parts.length - 1];
    console.log(token);

    form.addEventListener('submit', async (event) => {
        event.preventDefault();

        if (!form.checkValidity()) {
            event.stopPropagation();
            form.classList.add('was-validated');
            return;
        }
        const password = (document.getElementById('password') as HTMLInputElement).value;
        const retypedPassword = (document.getElementById('retypedPassword') as HTMLInputElement).value;

        if (password !== retypedPassword) {
            alert.displayMessage({
                message: 'Passwords do not match',
                type: 'danger',
            });
            return;
        }
        const formData = new FormData(form);
        const data = {
            password: formData.get('password'),
        };

        try {
            const response = await fetch('/api/auth/reset-password/' + token, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data),
            });

            const res = await response.json();

            if (!response.ok) {
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
        } catch (error) {
            alert.displayMessage({
                message: 'An error occurred. Please try again.',
                type: 'danger',
            });
            successMessage.classList.add('d-none');
        }
    });
});
