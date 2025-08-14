import 'datatables.net-bs5/css/dataTables.bootstrap5.css';
import 'datatables.net-responsive-bs5';

import DataTable from 'datatables.net-bs5';
import type { Api } from 'datatables.net-bs5';
import { Modal } from 'bootstrap';
import { showErrorModal, showSuccessModal, createQuestion } from '../../components';

type ResourceDataType = {
    id: number;
    name: string;
    description: string;
    facility_id: number;
    facility: { id: number; name: string };
    createdAt: Date;
    updatedAt?: Date;
    deletedAt?: Date;
};

const API_URL = '/api/areas';
const API_FACILITIES_URL = '/api/facilities';

const data: ResourceDataType[] = [];
let currentEditingData: ResourceDataType | null = null;
const form = document.getElementById('resourceForm') as HTMLFormElement;
const modalElement = document.getElementById('addResourceModal')!;
const facilitySelect = document.getElementById('inputFacility') as HTMLSelectElement;
let modal: Modal = {} as Modal;

document.addEventListener('DOMContentLoaded', () => {
    modal = new Modal(modalElement, { keyboard: false, backdrop: false });

    const datatable = initializeDataTable();
    loadFacilities();
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
            lengthMenu: 'Showing _MENU_ areas',
            zeroRecords: 'No areas found',
            emptyTable: 'No areas available in this table',
            info: 'Showing areas from _START_ to _END_ (of _TOTAL_)',
            infoEmpty: 'Empty table',
            infoFiltered: '',
            search: 'Search:',
            loadingRecords: 'Loading...',
        },
        columns: [
            { data: 'name' },
            { data: 'description' },
            {
                data: 'facility.name',
                defaultContent: 'N/A',
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
                const addButton = document.createElement('button');
                addButton.type = 'button';
                addButton.className = 'btn btn-primary mb-3';
                addButton.dataset.bsToggle = 'modal';
                addButton.dataset.bsTarget = '#addResourceModal';
                addButton.innerHTML = 'Add Area';
                return addButton;
            },
        },
    });
}

async function loadFacilities() {
    try {
        const response = await fetch(API_FACILITIES_URL);
        if (!response.ok) {
            throw new Error('Failed to fetch facilities');
        }

        const { data } = await response.json();

        // Clear current options except the placeholder
        facilitySelect.innerHTML = '<option value="" selected disabled>Choose a facility...</option>';

        // Add new options
        data.forEach((facility: { id: number; name: string }) => {
            const option = document.createElement('option');
            option.value = facility.id.toString();
            option.textContent = facility.name;
            facilitySelect.appendChild(option);
        });
    } catch (error) {
        console.error('Error loading facilities:', error);
        showErrorModal('Failed to load facilities');
    }
}

function setupModalEvents() {
    modalElement.addEventListener('hidden.bs.modal', () => {
        resetForm();
        currentEditingData = null;
        // Limpiar el backdrop manualmente
        const backdrop = document.querySelector('.modal-backdrop');
        if (backdrop) {
            backdrop.remove();
        }
        document.body.classList.remove('modal-open');
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
        //modal.hide();
    });
}

async function handleFormSubmit(datatable: Api<ResourceDataType>) {
    const nameInput = document.getElementById('inputName') as HTMLInputElement;
    const descriptionInput = document.getElementById('inputDescription') as HTMLTextAreaElement;
    const facilityInput = document.getElementById('inputFacility') as HTMLSelectElement;

    const newData = {
        name: nameInput.value.trim(),
        description: descriptionInput.value.trim(),
        facility_id: parseInt(facilityInput.value),
    };

    if (currentEditingData && isDataUnchanged(newData)) {
        showErrorModal('No changes made');
        return;
    }

    try {
        const url = currentEditingData ? `${API_URL}/${currentEditingData.id}` : API_URL;
        const method = currentEditingData ? 'PATCH' : 'POST';

        const response = await fetch(url, {
            method,
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(newData),
        });

        if (!response.ok) {
            const data = await response.json();
            throw new Error(data.message || 'Failed to save area');
        }

        datatable.ajax.reload();
        modal.hide();
        showSuccessModal(currentEditingData ? 'Area updated successfully' : 'Area created successfully');
        resetForm();
    } catch (error: any) {
        showErrorModal(error.message);
    }
}

function updateData(newData: ResourceDataType, datatable: Api<ResourceDataType>) {
    const index = data.findIndex((item) => item.id === newData.id);
    if (index !== -1) {
        data[index] = newData;
    } else {
        data.push(newData);
    }
    datatable.clear().rows.add(data).draw();
}

function isDataUnchanged(newData: Partial<ResourceDataType>) {
    if (!currentEditingData) return false;

    return (
        newData.name === currentEditingData.name &&
        newData.description === currentEditingData.description &&
        newData.facility_id === currentEditingData.facility_id
    );
}

function setupTableClickEvents(datatable: Api<ResourceDataType>) {
    document.querySelector('#resource-dt tbody')?.addEventListener('click', (event) => {
        const target = event.target as HTMLElement;
        const button = target.closest('button');
        if (!button) return;

        const tr = target.closest('tr');
        if (!tr) return;

        const rowData = datatable.row(tr).data();
        if (!rowData) return;

        if (button.id === 'editButton') {
            handleEditButtonClick(rowData);
        } else if (button.id === 'deleteButton') {
            handleDeleteButtonClick(rowData, datatable);
        }
    });
}

function handleEditButtonClick(editedData: ResourceDataType) {
    currentEditingData = editedData;

    const nameInput = document.getElementById('inputName') as HTMLInputElement;
    const descriptionInput = document.getElementById('inputDescription') as HTMLTextAreaElement;
    const facilityInput = document.getElementById('inputFacility') as HTMLSelectElement;
    const modalTitle = document.getElementById('modalTitle') as HTMLElement;
    const addButton = document.getElementById('addButton') as HTMLButtonElement;

    nameInput.value = editedData.name;
    descriptionInput.value = editedData.description;
    facilityInput.value = editedData.facility_id.toString();

    modalTitle.textContent = 'Edit area';
    addButton.textContent = 'Update';

    modal.show();
}

function handleDeleteButtonClick(targetData: ResourceDataType, datatable: Api<ResourceDataType>) {
    createQuestion({
        title: 'Delete area',
        text: `Are you sure you want to delete the area "${targetData.name}"? This action cannot be undone.`,
        confirmButtonText: 'Yes, delete it',
        cancelButtonText: 'Cancel',
        confirmButtonColor: 'danger',
        afterConfirm: async () => {
            await deleteResource(targetData.id, datatable);
            showSuccessModal('Area deleted successfully');
        },
    });
}

async function deleteResource(dataId: number, datatable: Api<ResourceDataType>) {
    const response = await fetch(`${API_URL}/${dataId}`, {
        method: 'DELETE',
    });

    if (!response.ok) {
        const data = await response.json();
        throw new Error(data.message || 'Failed to delete area');
    }

    datatable.ajax.reload();
}

function resetForm() {
    const nameInput = document.getElementById('inputName') as HTMLInputElement;
    const descriptionInput = document.getElementById('inputDescription') as HTMLTextAreaElement;
    const facilityInput = document.getElementById('inputFacility') as HTMLSelectElement;
    const modalTitle = document.getElementById('modalTitle') as HTMLElement;
    const addButton = document.getElementById('addButton') as HTMLButtonElement;

    nameInput.value = '';
    descriptionInput.value = '';
    facilityInput.value = '';

    modalTitle.textContent = 'Add an area';
    addButton.textContent = 'Save';

    form.classList.remove('was-validated');
}
