import { BasicAlert } from '../../components/alerts';

document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('loginForm') as HTMLFormElement;
    const formAlert = new BasicAlert('formAlerts');

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
            password: formData.get('password'),
            rememberMe: formData.get('rememberMe') === 'on',
        };

        if (!data.email || !data.password) return;

        try {
            const response = await fetch(`/api/auth/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data),
            });

            const resObj = await response.json();
            console.log(resObj);
            if (!response.ok) {
                return formAlert.displayMessage({ message: resObj.error, type: 'danger' });
            }
            window.location.href = '/';
        } catch (error) {
            console.error('Error during login:', error);
            formAlert.displayMessage({ message: 'An error occurred while trying to login.', type: 'danger' });
        }
    });
});
