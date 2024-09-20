import 'bootstrap/js/dist/collapse';
import 'bootstrap/js/dist/dropdown';

import Modal from 'bootstrap/js/dist/modal';
import { showErrorModal } from '../components/modals';

const button = document.getElementById('sidebarCollapse')!;
const sidebar = document.getElementById('sidebarMenu')!;
const logoutButton = document.getElementById('logoutButton')!;
const modalElement = document.getElementById('statusSuccessModal')!;

button.addEventListener('click', () => {
    console.log('Toggling sidebar');
    sidebar.classList.toggle('collapse');
});

logoutButton.addEventListener('click', () => {
    console.log('Logging out');
    fetch('/api/auth/logout', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({}),
    })
        .then((response) => {
            if (!response.ok) {
                throw new Error('Logout failed');
            }
            const successModal = new Modal(modalElement);

            modalElement.addEventListener('hidden.bs.modal', function () {
                window.location.href = '/auth/login';
            });
            successModal.show();
        })
        .catch((e) => {
            console.error(e);
            showErrorModal('Error', 'An error has occurred while trying to logout.');
        });
});
