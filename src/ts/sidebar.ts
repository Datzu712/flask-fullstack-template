import * as bootstrap from 'bootstrap';

import { showErrorModal } from "./components/modals.component";

const button = document.getElementById('sidebarCollapse')!;
const sidebar = document.getElementById('sidebarMenu')!;

button.addEventListener('click', () => {
    sidebar.classList.toggle('collapse');
});

const logoutButton = document.getElementById('logoutButton')!;
logoutButton.addEventListener('click', () => {
    fetch('{{ url_for("api.auth.logout") }}', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    }).then((response) => {
        if (!response.ok) {
            throw new Error();
        }
        const modalElement = document.getElementById('statusSuccessModal')!;
        const successModal = new bootstrap.Modal(modalElement);

        modalElement.addEventListener('hidden.bs.modal', function() {
            window.location.href = "{{ url_for('app.auth.login') }}";
        });
        successModal.show();
    }).catch((e) => {
        console.error(e);
        showErrorModal('Error', 'An error has ocurred while trying to logout.');
    });
});