import 'datatables.net-bs5/css/dataTables.bootstrap5.css';
import 'datatables.net-responsive-bs5';

import { Modal } from 'bootstrap';
import DataTable from 'datatables.net-bs5';
import { Api } from 'datatables.net';
import { createQuestion } from '@components/modals';

type ResourceDataType = {
    id: number;
    name: string;
    description: string;
    area_id: number;
    area: { id: number; name: string };
    created_at: string;
    deleted_at?: string;
};

type Area = {
    id: number;
    name: string;
    description: string;
    facility_id: number;
    facility: { id: number; name: string };
    createdAt: Date;
    updatedAt?: Date;
    deletedAt?: Date;
};

const API_URL = '/api/rooms';
const API_AREAS_URL = '/api/areas';

const data: ResourceDataType[] = [];
let currentEditingData: ResourceDataType | null = null;
const form = document.getElementById('resourceForm') as HTMLFormElement;
const modalElement = document.getElementById('addResourceModal')!;
const areaSelect = document.getElementById('inputArea') as HTMLSelectElement;
let modal: Modal = {} as Modal;
const areas = [] as Area[];

document.addEventListener('DOMContentLoaded', async () => {
    modal = new Modal(modalElement, { keyboard: false });

    await loadAreas();

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
            lengthMenu: 'Showing _MENU_ rooms',
            zeroRecords: 'No rooms found',
            emptyTable: 'No rooms available in this table',
            info: 'Showing rooms from _START_ to _END_ (of _TOTAL_)',
            infoEmpty: 'Empty table',
            infoFiltered: '',
            search: 'Search:',
            loadingRecords: 'Loading...',
        },
        columns: [
            { data: 'name' },
            { data: 'description' },
            {
                data: 'area_id',
                defaultContent: 'N/A',
                render: (targetArea) => {
                    console.log(`Trying to find ${targetArea} in: `, areas.map((a) => a.id).join(', '));
                    const area = areas.find((area) => area.id === targetArea);
                    return area ? area.name : 'N/A';
                },
            },
            {
                data: 'created_at',
                render: (data: string) => new Date(data).toLocaleDateString(),
            },
            {
                data: 'updated_at',
                defaultContent: 'N/A',
                render: (data: string) => new Date(data).toLocaleDateString(),
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
                div.innerHTML = `<button type="button" class="btn btn-primary mb-3">Add room</button>`;
                div.addEventListener('click', () => modal.show());

                return div;
            },
        },
    });
}

async function loadAreas() {
    try {
        const response = await fetch(API_AREAS_URL);
        const data = await response.json();

        areas.push(...data.data);

        areaSelect.innerHTML = '<option value="" selected disabled>Choose an area...</option>';

        data.data.forEach((area: { id: number; name: string }) => {
            const option = document.createElement('option');
            option.value = area.id.toString();
            option.textContent = area.name;
            areaSelect.appendChild(option);
        });
    } catch (error) {
        console.error('Error loading areas:', error);
    }
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
        modal.hide();
        resetForm();
    });
}

async function handleFormSubmit(datatable: Api<ResourceDataType>) {
    const nameInput = document.getElementById('inputName') as HTMLInputElement;
    const descriptionInput = document.getElementById('inputDescription') as HTMLTextAreaElement;
    const areaInput = document.getElementById('inputArea') as HTMLSelectElement;

    const newData = {
        name: nameInput.value,
        description: descriptionInput.value,
        area_id: parseInt(areaInput.value),
    };

    if (currentEditingData && isDataUnchanged(newData)) {
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
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const responseData = await response.json();
        updateData(responseData, datatable);
    } catch (error) {
        console.error('Error:', error);
    }
}

function updateData(newData: ResourceDataType, datatable: Api<ResourceDataType>) {
    const existingDataIndex = data.findIndex((item) => item.id === newData.id);
    if (existingDataIndex !== -1) {
        data[existingDataIndex] = newData;
    } else {
        data.push(newData);
    }
    datatable.ajax.reload();
}

function isDataUnchanged(newData: Partial<ResourceDataType>) {
    return (
        currentEditingData &&
        currentEditingData.name === newData.name &&
        currentEditingData.description === newData.description &&
        currentEditingData.area_id === newData.area_id
    );
}

function setupTableClickEvents(datatable: Api<ResourceDataType>) {
    const tableBody = document.querySelector('#resource-dt tbody');
    if (!tableBody) return;

    tableBody.addEventListener('click', (event) => {
        const target = event.target as HTMLElement;

        if (target.closest('#editButton')) {
            const tr = target.closest('tr') as HTMLTableRowElement;
            const rowData = datatable.row(tr).data();
            handleEditButtonClick(rowData);
        }

        if (target.closest('#deleteButton')) {
            const tr = target.closest('tr') as HTMLTableRowElement;
            const rowData = datatable.row(tr).data();
            handleDeleteButtonClick(rowData, datatable);
        }
    });
}

function handleEditButtonClick(editedData: ResourceDataType) {
    currentEditingData = editedData;

    const nameInput = document.getElementById('inputName') as HTMLInputElement;
    const descriptionInput = document.getElementById('inputDescription') as HTMLTextAreaElement;
    const areaInput = document.getElementById('inputArea') as HTMLSelectElement;

    nameInput.value = editedData.name;
    descriptionInput.value = editedData.description;
    areaInput.value = editedData.area_id.toString();

    document.getElementById('modalTitle')!.textContent = 'Edit room';
    document.getElementById('addButton')!.textContent = 'Save changes';
    modal.show();
}

function handleDeleteButtonClick(targetData: ResourceDataType, datatable: Api<ResourceDataType>) {
    createQuestion({
        title: 'Are you sure?',
        text: `Are you sure you want to delete the room "${targetData.name}"? This action cannot be undone.`,
        confirmButtonText: "Yes, I'm sure",
        cancelButtonText: 'Cancel',
        confirmButtonColor: 'danger',
        afterConfirm: () => deleteResource(targetData.id, datatable),
    });
}

async function deleteResource(dataId: number, datatable: Api<ResourceDataType>) {
    try {
        const response = await fetch(`${API_URL}/${dataId}`, {
            method: 'DELETE',
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const index = data.findIndex((item) => item.id === dataId);
        if (index > -1) {
            data.splice(index, 1);
        }
        datatable.ajax.reload();
    } catch (error) {
        console.error('Error:', error);
    }
}

function resetForm() {
    form.reset();
    form.classList.remove('was-validated');
    document.getElementById('modalTitle')!.textContent = 'Add a room';
    document.getElementById('addButton')!.textContent = 'Save';
}
