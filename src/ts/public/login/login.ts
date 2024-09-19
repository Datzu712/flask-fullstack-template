import { showErrorModal } from '../../components/modals';

document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('loginForm') as HTMLFormElement;

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
            if (!response.ok) {
                return showErrorModal(resObj.error, 'Login error');
            }
            window.location.href = '/';
        } catch (error) {
            console.error('Error during login:', error);
            showErrorModal('The email or password is incorrect.', 'Credentials error');
        }
    });
});
