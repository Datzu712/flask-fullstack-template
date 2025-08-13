import 'datatables.net-bs5/css/dataTables.bootstrap5.css';
import 'datatables.net-responsive-bs5';

import DataTable from 'datatables.net-bs5';
import type { Api } from 'datatables.net-bs5';
import Modal from 'bootstrap/js/dist/modal';
import { createQuestion, showErrorModal, showSuccessModal } from '../../components/modals';

type ResourceDataType = {
    id: number;
    first_name: string;
    last_name: string;
    date_of_birth: Date;
    gender: number;
    phone?: string;
    email: string;
    address?: string;
    createdAt: Date;
    updatedAt?: Date;
    deletedAt?: Date;
};

const API_URL = '/api/patients';

const data: ResourceDataType[] = [];
let currentEditingData: ResourceDataType | null = null;
const form = document.getElementById('resourceForm') as HTMLFormElement;
const modalElement = document.getElementById('addResourceModal')!;
let modal: Modal = {} as Modal;

document.addEventListener('DOMContentLoaded', () => {
    modal = new Modal(modalElement, { keyboard: false });

    const datatable = initializeDataTable();
    setupModalEvents();
    setupFormSubmit(datatable);
    setupTableClickEvents(datatable);
});

function initializeDataTable() {
    return new DataTable<ResourceDataType>('#resource-dt', {
        ajax: {
            dataSrc: 'data',
            url: API_URL,
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
            { data: 'first_name' },
            { data: 'last_name' },
            {
                data: 'date_of_birth',
                render: (data: string) => new Date(data).toLocaleDateString(),
            },
            {
                data: null,
                render: (data: any) => {
                    return data.gender === 0 ? 'Male' : 'Female';
                },
            },
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
        currentEditingData = null;
    });
}

function setupFormSubmit(datatable: Api<ResourceDataType>) {
    form.addEventListener('submit', (event) => {
        event.preventDefault();
        if (!form.checkValidity()) {
            event.stopPropagation();
        } else {
            handleFormSubmit(datatable);
        }
        form.classList.add('was-validated');
    });
}

function handleFormSubmit(datatable: Api<ResourceDataType>) {
    const genderMaleInput = document.getElementById('genderMale') as HTMLInputElement;
    const genderFemaleInput = document.getElementById('genderFemale') as HTMLInputElement;

    let gender: number | null = null;
    if (genderMaleInput.checked) {
        gender = 0; // Male
    } else if (genderFemaleInput.checked) {
        gender = 1; // Female
    }

    if (gender === null) {
        showErrorModal('Please select a gender', 'warning');
        return;
    }

    const newData = {
        first_name: (document.getElementById('inputFirstName') as HTMLInputElement).value,
        last_name: (document.getElementById('inputLastName') as HTMLInputElement).value,
        date_of_birth: new Date((document.getElementById('inputDob') as HTMLInputElement).value),
        gender,
        email: (document.getElementById('inputEmail') as HTMLInputElement).value,
        phone: (document.getElementById('inputPhone') as HTMLInputElement).value || undefined,
        address: (document.getElementById('inputAddress') as HTMLInputElement).value || undefined,
        ...(currentEditingData ? { id: currentEditingData.id } : {}),
    } as Partial<ResourceDataType>;

    if (currentEditingData && isDataUnchanged(newData)) {
        showErrorModal('No changes were made', 'warning');
        return;
    }

    const method = currentEditingData ? 'PATCH' : 'POST';
    const url = API_URL + (currentEditingData ? `/${currentEditingData.id}` : '');

    fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newData),
    })
        .then((res) => handleResponse(res, newData, datatable))
        .catch((error) => {
            console.error(error);
            showErrorModal(
                `An error occurred while ${currentEditingData ? 'editing' : 'creating'} the client`,
                'Error',
            );
        });
}

function handleResponse(res: Response, newData: Partial<ResourceDataType>, datatable: Api<ResourceDataType>) {
    if (!res.ok) {
        res.json().then(({ message }) => showErrorModal(message, 'danger'));
        throw new Error('Error processing the patient');
    }

    if (currentEditingData) {
        updateData(newData as ResourceDataType, datatable);
    } else {
        res.json().then((d) => {
            data.push(d);
            datatable.clear().rows.add(data).draw();
        });
    }
    modal.hide();
    showSuccessModal(`${currentEditingData ? 'Edited' : 'Created'} patient successful!`);
}

function updateData(newData: ResourceDataType, datatable: Api<ResourceDataType>) {
    const index = data.findIndex((d) => d.id === currentEditingData!.id);
    data[index] = newData;
    datatable.clear().rows.add(data).draw();
}

function isDataUnchanged(newData: Partial<ResourceDataType>) {
    return Object.keys(newData).every(
        (key) => newData[key as keyof ResourceDataType] === currentEditingData![key as keyof ResourceDataType],
    );
}

function setupTableClickEvents(datatable: Api<ResourceDataType>) {
    document.querySelector('#resource-dt tbody')!.addEventListener('click', (event) => {
        const d = datatable.row((event.target as HTMLElement).closest('tr')!).data() as ResourceDataType;

        console.log('entro');
        switch ((event.target as HTMLElement).id) {
            case 'editButton':
                handleEditButtonClick(d);
                break;
            case 'deleteButton':
                handleDeleteButtonClick(d, datatable);
                break;
        }
    });
}

function handleEditButtonClick(editedData: ResourceDataType) {
    currentEditingData = { ...editedData };
    (document.getElementById('inputFirstName') as HTMLInputElement).value = editedData.first_name;
    (document.getElementById('inputLastName') as HTMLInputElement).value = editedData.last_name;
    (document.getElementById('inputDob') as HTMLInputElement).value = new Date(editedData.date_of_birth)
        .toISOString()
        .split('T')[0];
    (document.getElementById('inputEmail') as HTMLInputElement).value = editedData.email;
    (document.getElementById('inputPhone') as HTMLInputElement).value = editedData.phone || '';
    (document.getElementById('inputAddress') as HTMLInputElement).value = editedData.address || '';

    if (editedData.gender === 0) {
        (document.getElementById('genderMale') as HTMLInputElement).checked = true;
    } else if (editedData.gender === 1) {
        (document.getElementById('genderFemale') as HTMLInputElement).checked = true;
    }

    modal.show();
}

function handleDeleteButtonClick(targetData: ResourceDataType, datatable: Api<ResourceDataType>) {
    createQuestion({
        title: 'Are you sure?',
        text: `Are you sure you want to delete the patient "${targetData.first_name} ${targetData.last_name}"? This action cannot be undone.`,
        confirmButtonText: "Yes, I'm sure",
        cancelButtonText: 'Cancel',
        confirmButtonColor: 'danger',
        afterConfirm: () => deleteResource(targetData.id!, datatable),
    });
}

function deleteResource(dataId: number, datatable: Api<ResourceDataType>) {
    fetch(API_URL + '/' + dataId, { method: 'DELETE' })
        .then((response) => {
            if (!response.ok) {
                response.json().then(({ message }) => showErrorModal(message, 'danger'));
                return;
            }
            modal.hide();

            showSuccessModal('Removed patient successful!');
            const index = data.findIndex((client) => dataId === client.id);
            data.splice(index, 1);
            datatable.clear().rows.add(data).draw();
        })
        .catch((error) => console.error(error));
}

function resetForm() {
    form.classList.remove('was-validated');
    form.reset();
    form.querySelectorAll('input').forEach((input) => (input.value = ''));
}
