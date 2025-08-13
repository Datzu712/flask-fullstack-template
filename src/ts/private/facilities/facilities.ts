import 'datatables.net-bs5/css/dataTables.bootstrap5.css';
import 'datatables.net-responsive-bs5';

import DataTable from 'datatables.net-bs5';
import { Modal } from 'bootstrap';
import { Api } from 'datatables.net';
import { showErrorModal, showSuccessModal, createQuestion } from '../../components';

type ResourceDataType = {
    id: number;
    name: string;
    description: string;
    createdAt: Date;
    updatedAt?: Date;
    deletedAt?: Date;
};

const API_URL = '/api/facilities';

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
            lengthMenu: 'Showing _MENU_ facilities',
            zeroRecords: 'No facilities found',
            emptyTable: 'No facilities available in this table',
            info: 'Showing facilities from _START_ to _END_ (of _TOTAL_)',
            infoEmpty: 'Empty table',
            infoFiltered: '',
            search: 'Search:',
            loadingRecords: 'Loading...',
        },
        columns: [
            { data: 'name' },
            { data: 'description' },
            {
                data: 'created_at',
                render: (data: string) => new Date(data).toLocaleDateString(),
            },
            {
                data: 'updated_at',
                defaultContent: '',
                render: (data: string) => (data ? new Date(data).toLocaleDateString() : 'N/A'),
            },
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
    form.addEventListener('submit', async (event) => {
        event.preventDefault();
        event.stopPropagation();

        if (!form.checkValidity()) {
            form.classList.add('was-validated');
            return;
        }

        await handleFormSubmit(datatable);
        form.classList.remove('was-validated');
        modal.hide();
    });
}

async function handleFormSubmit(datatable: Api<ResourceDataType>) {
    const newData = {
        name: (document.getElementById('inputName') as HTMLInputElement).value,
        description: (document.getElementById('inputDescription') as HTMLTextAreaElement).value,
        ...(currentEditingData ? { id: currentEditingData.id } : {}),
    } as Partial<ResourceDataType>;

    if (currentEditingData && isDataUnchanged(newData)) {
        showSuccessModal('No changes detected');
        return;
    }

    const method = currentEditingData ? 'PATCH' : 'POST';
    const url = currentEditingData ? `${API_URL}/${currentEditingData.id}` : API_URL;

    try {
        const res = await fetch(url, {
            method,
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(newData),
        });

        if (!res.ok) {
            const error = await res.json();
            throw new Error(error.message || 'An error occurred');
        }

        const data = await res.json();
        updateData(data, datatable);
        showSuccessModal(`Facility ${currentEditingData ? 'updated' : 'created'} successfully`);
    } catch (error: any) {
        showErrorModal(error.message);
    }
}

function updateData(newData: ResourceDataType, datatable: Api<ResourceDataType>) {
    if (currentEditingData) {
        const index = data.findIndex((item) => item.id === currentEditingData!.id);
        if (index !== -1) {
            data[index] = newData;
        }
    } else {
        data.push(newData);
    }
    datatable.ajax.reload();
}

function isDataUnchanged(newData: Partial<ResourceDataType>) {
    if (!currentEditingData) return false;
    return newData.name === currentEditingData.name && newData.description === currentEditingData.description;
}

function setupTableClickEvents(datatable: Api<ResourceDataType>) {
    document.getElementById('resource-dt')?.addEventListener('click', (event) => {
        const target = event.target as HTMLElement;
        const button = target.closest('button');
        if (!button) return;

        const row = target.closest('tr');
        if (!row) return;

        const rowData = datatable.row(row).data();
        if (!rowData) return;

        if (button.id === 'editButton') {
            handleEditButtonClick(rowData);
        } else if (button.id === 'deleteButton') {
            handleDeleteButtonClick(rowData, datatable);
        }
    });

    // Add new facility button
    const addButton = document.createElement('button');
    addButton.className = 'btn btn-primary mb-3';
    addButton.textContent = 'Add Facility';
    addButton.onclick = () => {
        document.getElementById('modalTitle')!.textContent = 'Add a facility';
        document.getElementById('addButton')!.textContent = 'Add';
        modal.show();
    };
}

function handleEditButtonClick(editedData: ResourceDataType) {
    currentEditingData = editedData;
    document.getElementById('modalTitle')!.textContent = 'Edit facility';
    document.getElementById('addButton')!.textContent = 'Update';

    (document.getElementById('inputName') as HTMLInputElement).value = editedData.name;
    (document.getElementById('inputDescription') as HTMLTextAreaElement).value = editedData.description;

    modal.show();
}
function handleDeleteButtonClick(targetData: ResourceDataType, datatable: Api<ResourceDataType>) {
    createQuestion({
        title: 'Are you sure?',
        text: `Are you sure you want to delete the facility "${targetData.name}"? This action cannot be undone.`,
        confirmButtonText: "Yes, I'm sure",
        cancelButtonText: 'Cancel',
        confirmButtonColor: 'danger',
        afterConfirm: () => deleteResource(targetData.id, datatable),
    });
}

async function deleteResource(dataId: number, datatable: Api<ResourceDataType>) {
    try {
        const res = await fetch(`${API_URL}/${dataId}`, {
            method: 'DELETE',
        });

        if (!res.ok) {
            const error = await res.json();
            throw new Error(error.message || 'An error occurred');
        }

        const index = data.findIndex((item) => item.id === dataId);
        if (index !== -1) {
            data.splice(index, 1);
        }

        datatable.ajax.reload();
        showSuccessModal('Facility deleted successfully');
    } catch (error: any) {
        showErrorModal(error.message);
    }
}

function resetForm() {
    form.reset();
    form.classList.remove('was-validated');
}
