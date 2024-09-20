import { showErrorModal } from '@components/modals';
import Modal from 'bootstrap/js/dist/modal';

document.getElementById('registerForm')!.addEventListener('submit', function (event) {
    event.preventDefault();

    const form = event.target as HTMLFormElement;
    const formData = new FormData(form);

    const data = {
        username: formData.get('username'),
        email: formData.get('email'),
        password: formData.get('password'),
    };
    console.log(data);
    if (data.password !== formData.get('confirm_password')) {
        showErrorModal('Passwords do not match.', 'Please try again.');
        return;
    }

    fetch('/api/auth/register', {
        method: 'POST',
        body: JSON.stringify(data),
        headers: {
            'Content-Type': 'application/json',
        },
    })
        .then((res) => {
            if (!res.ok) {
                throw new Error('An error occurred while processing your request.');
            }
            const modalElement = document.getElementById('statusSuccessModal')!;
            const successModal = new Modal(modalElement);

            modalElement.addEventListener('hidden.bs.modal', function () {
                window.location.href = '/auth/login';
            });
            successModal.show();
        })
        .catch((error) => {
            console.error(error);
            showErrorModal(`Couldn't create a user. Probably that email already exists!`, 'Please try again later.');
        });
});
