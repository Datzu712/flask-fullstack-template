import 'datatables.net-bs5/css/dataTables.bootstrap5.css';
import 'datatables.net-responsive-bs5';

import DataTable from 'datatables.net-bs5';
import { Api } from 'datatables.net';
import { Modal } from 'bootstrap';
import { showErrorModal, showSuccessModal } from '../../components/modals';

type ResourceDataType = {
    id: number;
    username: string;
    email: string;
    role: string;
    is_active: number;
    created_at: Date;
    updated_at?: Date;
    deleted_at?: Date;
    password?: string;
};

const API_URL = '/api/users';

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
            lengthMenu: 'Showing _MENU_ users',
            zeroRecords: 'No users found',
            emptyTable: 'No users available in this table',
            info: 'Showing users from _START_ to _END_ (of _TOTAL_)',
            infoEmpty: 'Empty table',
            infoFiltered: '',
            search: 'Search:',
            loadingRecords: 'Loading...',
        },
        columns: [
            { data: 'username' },
            { data: 'email' },
            { data: 'role', defaultContent: 'N/A' },
            {
                data: 'is_active',
                render: (data: number) => (data === 1 ? 'Active' : 'Inactive'),
            },
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
                div.innerHTML = `<button type="button" class="btn btn-primary mb-3">Add user</button>`;
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

        // Show password field by default (for new users)
        const passwordField = document.querySelector('.password-field') as HTMLElement;
        if (passwordField) {
            passwordField.style.display = 'block';
            (document.getElementById('inputPassword') as HTMLInputElement).required = true;
        }
    });
}

function setupFormSubmit(datatable: Api<ResourceDataType>) {
    form.addEventListener('submit', async (event) => {
        event.preventDefault();
        event.stopPropagation();

        if (!form.checkValidity()) {
            event.stopPropagation();
            form.classList.add('was-validated');
            return;
        }

        await handleFormSubmit(datatable);
    });
}

async function handleFormSubmit(datatable: Api<ResourceDataType>) {
    const newData = {
        username: (document.getElementById('inputUsername') as HTMLInputElement).value,
        email: (document.getElementById('inputEmail') as HTMLInputElement).value,
        role: (document.getElementById('selectRole') as HTMLSelectElement).value,
        is_active: (document.getElementById('checkActive') as HTMLInputElement).checked ? 1 : 0,
        ...(currentEditingData ? { id: currentEditingData.id } : {}),
    } as Partial<ResourceDataType>;

    // Add password only if provided (required for new users, optional for edits)
    const passwordInput = document.getElementById('inputPassword') as HTMLInputElement;
    if (passwordInput.value) {
        newData.password = passwordInput.value;
    }

    if (currentEditingData && isDataUnchanged(newData)) {
        modal.hide();
        return;
    }

    const method = currentEditingData ? 'PATCH' : 'POST';
    const url = currentEditingData ? `${API_URL}/${currentEditingData.id}` : API_URL;

    try {
        const response = await fetch(url, {
            method,
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(newData),
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || 'An error occurred');
        }

        const responseData = await response.json();
        updateData(responseData, datatable);
        showSuccessModal(`User ${currentEditingData ? 'updated' : 'created'} successfully`);
        modal.hide();
    } catch (error: any) {
        showErrorModal(error.message || 'An error occurred');
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

    return (
        newData.username === currentEditingData.username &&
        newData.email === currentEditingData.email &&
        newData.role === currentEditingData.role &&
        newData.is_active === currentEditingData.is_active
    );
}

function setupTableClickEvents(datatable: Api<ResourceDataType>) {
    document.addEventListener('click', (event) => {
        const target = event.target as HTMLElement;
        const editButton = target.closest('#editButton');
        const deleteButton = target.closest('#deleteButton');

        if (!editButton && !deleteButton) return;

        const tr = (editButton || deleteButton)!.closest('tr');
        if (!tr) return;

        const rowData = datatable.row(tr).data() as ResourceDataType;

        if (editButton) {
            event.preventDefault();
            handleEditButtonClick(rowData);
        } else if (deleteButton) {
            event.preventDefault();
            handleDeleteButtonClick(rowData, datatable);
        }
    });
}

function handleEditButtonClick(editedData: ResourceDataType) {
    currentEditingData = editedData;
    document.getElementById('modalTitle')!.textContent = 'Edit user';

    (document.getElementById('inputUsername') as HTMLInputElement).value = editedData.username;
    (document.getElementById('inputEmail') as HTMLInputElement).value = editedData.email;
    (document.getElementById('selectRole') as HTMLSelectElement).value = editedData.role || 'receptionist';
    (document.getElementById('checkActive') as HTMLInputElement).checked = editedData.is_active === 1;

    // Hide password field for editing (password is optional for updates)
    const passwordField = document.querySelector('.password-field') as HTMLElement;
    if (passwordField) {
        passwordField.style.display = 'none';
        (document.getElementById('inputPassword') as HTMLInputElement).required = false;
    }

    modal.show();
}

function handleDeleteButtonClick(targetData: ResourceDataType, datatable: Api<ResourceDataType>) {
    if (confirm(`Are you sure you want to delete user ${targetData.username}?`)) {
        deleteResource(targetData.id, datatable);
    }
}

async function deleteResource(dataId: number, datatable: Api<ResourceDataType>) {
    try {
        const response = await fetch(`${API_URL}/${dataId}`, {
            method: 'DELETE',
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || 'Failed to delete user');
        }

        datatable.ajax.reload();
        showSuccessModal('User deleted successfully');
    } catch (error: any) {
        showErrorModal(error.message || 'Failed to delete user');
    }
}

function resetForm() {
    form.reset();
    form.classList.remove('was-validated');
    document.getElementById('modalTitle')!.textContent = 'Add a user';

    // Reset required state for password
    const passwordInput = document.getElementById('inputPassword') as HTMLInputElement;
    if (passwordInput) {
        passwordInput.required = true;
    }
}
