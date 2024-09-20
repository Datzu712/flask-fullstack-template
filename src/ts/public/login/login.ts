import { BasicAlert } from '@components/alerts';
import type { IUserData } from '@interfaces/userData';

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
        if (!data.email || !data.password) return console.error('Validation failed');

        try {
            const response = await fetch(`/api/auth/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data),
            });

            const resObj: { error?: string; data: IUserData } = await response.json();
            if (!response.ok) {
                return formAlert.displayMessage({
                    message: resObj.error || 'An error ocurred while trying to login.',
                    type: 'danger',
                });
            }
            localStorage.setItem('user_data', JSON.stringify(resObj.data));

            window.location.href = '/';
        } catch (error) {
            console.error('Error during login:', error);
            formAlert.displayMessage({ message: 'An error occurred while trying to login.', type: 'danger' });
        }
    });
});
