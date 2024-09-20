import 'datatables.net-bs5/css/dataTables.bootstrap5.css';
import 'datatables.net-responsive-bs5';

import DataTable from 'datatables.net-bs5';
import type { Api } from 'datatables.net-bs5';
import Modal from 'bootstrap/js/dist/modal';
import { createQuestion, showErrorModal, showSuccessModal } from '../../components/modals';

type Client = {
    id?: number;
    name: string;
    email: string;
    phone: string;
    address: string;
};

const clientsData: Client[] = [];
let currentEditingClient: Client | null = null;
const form = document.getElementById('clientForm') as HTMLFormElement;
const modalElement = document.getElementById('addClientModal')!;
let modal: Modal = {} as Modal;

document.addEventListener('DOMContentLoaded', () => {
    modal = new Modal(modalElement, { keyboard: false });

    const clientDT = initializeDataTable();
    setupModalEvents();
    setupFormSubmit(clientDT);
    setupTableClickEvents(clientDT);
});

function initializeDataTable() {
    return new DataTable<Client>('#clients-dt', {
        ajax: {
            dataSrc: function (json) {
                clientsData.push(...json);
                return json;
            },
            url: '/api/clients',
        },
        responsive: true,
        autoWidth: true,
        language: {
            processing: 'Processing...',
            lengthMenu: 'Showing _MENU_ clients',
            zeroRecords: 'No clients found',
            emptyTable: 'No clients available in this table',
            info: 'Showing clients from _START_ to _END_ (of _TOTAL_)',
            infoEmpty: 'Empty table',
            infoFiltered: '',
            search: 'Search:',
            loadingRecords: 'Loading...',
        },
        columns: [
            { data: 'name' },
            { data: 'email' },
            { data: 'phone' },
            { data: 'address' },
            {
                orderable: false,
                data: null,
                render: () => `
                    <div class="btn-group">
                        <button class="btn btn-primary dropdown-toggle" data-bs-toggle="dropdown" aria-expanded="false">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-list"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M9 6l11 0" /><path d="M9 12l11 0" /><path d="M9 18l11 0" /><path d="M5 6l0 .01" /><path d="M5 12l0 .01" /><path d="M5 18l0 .01" /></svg>
                        </button>
                        <ul class="dropdown-menu dropdown-menu-end">
                            <li><button id="editButton" class="dropdown-item">Edit</button></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><button id="deleteButton" class="dropdown-item">Delete</button></li>
                        </ul>
                    </div>
                `,
                width: '1%',
            },
        ],
        layout: {
            // @ts-expect-error todo
            top: () => {
                const div = document.createElement('div');
                div.innerHTML = `<button type="button" class="btn btn-primary mb-3">Add client</button>`;
                div.addEventListener('click', () => modal.show());

                return div;
            },
        },
    });
}

function setupModalEvents() {
    modalElement.addEventListener('hidden.bs.modal', () => {
        resetForm();
        currentEditingClient = null;
    });
}

function setupFormSubmit(clientDT: Api<Client>) {
    form.addEventListener('submit', (event) => {
        event.preventDefault();
        if (!form.checkValidity()) {
            event.stopPropagation();
        } else {
            handleFormSubmit(clientDT);
        }
        form.classList.add('was-validated');
    });
}

function handleFormSubmit(clientDT: Api<Client>) {
    const newClient: Client = {
        name: (document.getElementById('inputName') as HTMLInputElement).value,
        email: (document.getElementById('inputEmail') as HTMLInputElement).value,
        phone: (document.getElementById('inputPhone') as HTMLInputElement).value,
        address: (document.getElementById('inputAddress') as HTMLInputElement).value,
        ...(currentEditingClient ? { id: currentEditingClient.id } : {}),
    };

    if (currentEditingClient && isClientUnchanged(newClient)) {
        showErrorModal('No changes were made', 'warning');
        return;
    }

    const method = currentEditingClient ? 'PATCH' : 'POST';
    const url = '/api/clients' + (currentEditingClient ? `/${currentEditingClient.id}` : '');

    fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newClient),
    })
        .then((res) => handleResponse(res, newClient, clientDT))
        .catch((error) => {
            console.error(error);
            showErrorModal(
                `An error occurred while ${currentEditingClient ? 'editing' : 'creating'} the client`,
                'Error',
            );
        });
}

function handleResponse(res: Response, newClient: Client, clientDT: Api<Client>) {
    if (!res.ok) {
        res.json().then(({ message }) => showErrorModal(message, 'danger'));
        throw new Error('Error processing the client');
    }

    if (currentEditingClient) {
        updateClient(newClient, clientDT);
    } else {
        res.json().then((d) => {
            clientsData.push(d);
            clientDT.clear().rows.add(clientsData).draw();
        });
    }
    modal.hide();
    showSuccessModal(`${currentEditingClient ? 'Edited' : 'Created'} client successful!`);
}

function updateClient(newClient: Client, clientDT: Api<Client>) {
    const index = clientsData.findIndex((client) => client.id === currentEditingClient!.id);
    clientsData[index] = newClient;
    clientDT.clear().rows.add(clientsData).draw();
}

function isClientUnchanged(newClient: Client) {
    return Object.keys(newClient).every(
        (key) => newClient[key as keyof Client] === currentEditingClient![key as keyof Client],
    );
}

function setupTableClickEvents(clientDT: Api<Client>) {
    document.querySelector('#clients-dt tbody')!.addEventListener('click', (event) => {
        const d = clientDT.row((event.target as HTMLElement).closest('tr')!).data() as Client;

        console.log('entro');
        switch ((event.target as HTMLElement).id) {
            case 'editButton':
                handleEditButtonClick(d);
                break;
            case 'deleteButton':
                handleDeleteButtonClick(d, clientDT);
                break;
        }
    });
}

function handleEditButtonClick(client: Client) {
    currentEditingClient = { ...client };
    (document.getElementById('inputName') as HTMLInputElement).value = client.name;
    (document.getElementById('inputEmail') as HTMLInputElement).value = client.email;
    (document.getElementById('inputPhone') as HTMLInputElement).value = client.phone;
    (document.getElementById('inputAddress') as HTMLInputElement).value = client.address;

    modal.show();
}

function handleDeleteButtonClick(client: Client, clientDT: Api<Client>) {
    createQuestion({
        title: 'Are you sure?',
        text: `Are you sure you want to delete the client "${client.name}"? This action cannot be undone.`,
        confirmButtonText: "Yes, I'm sure",
        cancelButtonText: 'Cancel',
        confirmButtonColor: 'danger',
        afterConfirm: () => deleteClient(client.id!, clientDT),
    });
}

function deleteClient(clientId: number, clientDT: Api<Client>) {
    fetch('/api/clients/' + clientId, { method: 'DELETE' })
        .then((response) => {
            if (!response.ok) {
                response.json().then(({ message }) => showErrorModal(message, 'danger'));
                return;
            }
            modal.hide();

            showSuccessModal('Removed client successful!');
            const index = clientsData.findIndex((client) => clientId === client.id);
            clientsData.splice(index, 1);
            clientDT.clear().rows.add(clientsData).draw();
        })
        .catch((error) => console.error(error));
}

function resetForm() {
    form.classList.remove('was-validated');
    form.reset();
    form.querySelectorAll('input').forEach((input) => (input.value = ''));
}
