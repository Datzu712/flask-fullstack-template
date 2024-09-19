import 'datatables.net-bs5/css/dataTables.bootstrap5.css';
//import 'bootstrap/js/dist/dropdown';

import DataTable from 'datatables.net-bs5';
import Modal from 'bootstrap/js/dist/modal';
import { createQuestion, showErrorModal, showSuccessModal } from './components/modals.component';

const clientsData = [] as any[];

let currentEditingClient: any = null;
const form = document.getElementById('clientForm') as HTMLFormElement;

const clientDT = new DataTable('#clients-dt', {
    data: clientsData as any,
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
            render: function () {
                return `
                    <div class="btn-group">
                        <button class="btn btn-primary dropdown-toggle" data-bs-toggle="dropdown" aria-expanded="false">
                            <svg  xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-list"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M9 6l11 0" /><path d="M9 12l11 0" /><path d="M9 18l11 0" /><path d="M5 6l0 .01" /><path d="M5 12l0 .01" /><path d="M5 18l0 .01" /></svg>
                        </button>
                        <ul class="dropdown-menu dropdown-menu-end">
                            <li><button id="editButton" class="dropdown-item">Edit</button></li>
                            <!-- <li><button id="reasignButton" class="dropdown-item">Give access</button></li> -->
                            <li><hr class="dropdown-divider"></li>
                            <li><button id="deleteButton" class="dropdown-item">Delete</button></li>
                        </ul>
                    </div>
                `;
            },
            //target: -1,
            width: '1%',
        },
    ],
    layout: {
        // @ts-ignore
        top: function () {
            const div = document.createElement('div');
            div.innerHTML = `<button type="button" class="btn btn-primary mb-3" data-bs-toggle="modal" data-bs-target="#addClientModal">Add client</button>`;

            return div;
        },
    },
});

const modal = new Modal(document.getElementById('addClientModal')!, {
    keyboard: false,
});
// @ts-ignore
modal._element.addEventListener('hidden.bs.modal', function () {
    form.classList.remove('was-validated');
    form.reset();

    const inputs = form.querySelectorAll('input');
    inputs.forEach((input) => {
        input.value = '';
    });
    currentEditingClient = null;
});

form.addEventListener('submit', function (event) {
    if (!form.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
    } else {
        event.preventDefault();

        const newClient = {
            name: (document.getElementById('inputName') as HTMLInputElement).value,
            email: (document.getElementById('inputEmail') as HTMLInputElement).value,
            phone: (document.getElementById('inputPhone') as HTMLInputElement).value,
            address: (document.getElementById('inputAddress') as HTMLInputElement).value,
            ...(currentEditingClient ? { id: currentEditingClient.id } : {}),
        };

        if (
            currentEditingClient &&
            Object.keys(newClient).every(
                (key) => newClient[key as keyof typeof newClient] === currentEditingClient[key],
            )
        ) {
            showErrorModal('No changes were made', 'warning');
            return;
        }

        fetch('/api/clients' + (currentEditingClient ? `/${currentEditingClient.id}` : ''), {
            method: currentEditingClient ? 'PATCH' : 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                name: (document.getElementById('inputName') as HTMLInputElement).value,
                email: (document.getElementById('inputEmail') as HTMLInputElement).value,
                phone: (document.getElementById('inputPhone') as HTMLInputElement).value,
                address: (document.getElementById('inputAddress') as HTMLInputElement).value,
            }),
        })
            .then((res) => {
                if (!res.ok) {
                    res.json().then(({ message }) => {
                        showErrorModal(message, 'danger');
                    });
                    throw new Error('Error al crear el cliente');
                }
                if (currentEditingClient) {
                    const index = clientsData.findIndex(
                        (client: any) => client.id === (currentEditingClient?.id as number),
                    );
                    clientsData[index] = newClient;
                    clientDT.clear().rows.add(clientsData).draw();
                } else {
                    res.json().then((d) => {
                        clientsData.push(d);
                        clientDT.clear().rows.add(clientsData).draw();
                    });
                }

                const modal = Modal.getInstance(document.getElementById('addClientModal')!)!;
                modal.hide();
                showSuccessModal(`${currentEditingClient ? 'Edited' : 'Created'} client successful!`);
            })
            .catch((error) => {
                console.error(error);
                showErrorModal(
                    `An error occurred while ${currentEditingClient ? 'creating' : 'editing'} the client`,
                    'Error',
                );
            });
    }
    form.classList.add('was-validated');
});

document.querySelector('#clients-dt tbody')!.addEventListener('click', function (event) {
    const d = clientDT.row((event.target as HTMLElement)!.closest('tr')!).data();

    switch ((event.target as HTMLElement).id) {
        case 'editButton':
            console.log('Edit', d);

            currentEditingClient = { ...d };

            (document.getElementById('inputName') as HTMLInputElement).value = d.name;
            (document.getElementById('inputEmail') as HTMLInputElement).value = d.email;
            (document.getElementById('inputPhone') as HTMLInputElement).value = d.phone;
            (document.getElementById('inputAddress') as HTMLInputElement).value = d.address;

            modal.show();
            break;
        case 'reasignButton':
            break;
        case 'deleteButton':
            const clientId = d.id;

            createQuestion({
                title: 'Are you sure?',
                text: `Are you sure you want to delete the client "${d.name}"? This action cannot be undone.`,
                confirmButtonText: "Yes, I'm sure",
                cancelButtonText: 'Cancel',
                confirmButtonColor: 'danger',
                afterConfirm: () => {
                    return fetch('/api/clients/' + clientId, {
                        method: 'DELETE',
                    })
                        .then((response) => {
                            if (!response.ok) {
                                response.json().then(({ message }) => {
                                    showErrorModal(message, 'danger');
                                });
                            }
                            showSuccessModal('Removed client successful!');

                            const index = clientsData.findIndex((client) => clientId === client.id);
                            clientsData.splice(index, 1);
                            clientDT.clear().rows.add(clientsData).draw();
                        })
                        .catch((error) => {
                            console.error(error);
                        });
                },
            });
            break;
    }
});
