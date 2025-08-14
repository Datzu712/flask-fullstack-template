import 'datatables.net-bs5/css/dataTables.bootstrap5.css';
import 'datatables.net-responsive-bs5';

import DataTable from 'datatables.net-bs5';
import type { Api } from 'datatables.net-bs5';
import { Modal } from 'bootstrap';
import { showErrorModal, showSuccessModal, createQuestion } from '../../components';

type ResourceDataType = {
    id: number;
    patient_id: number;
    doctor_id: number;
    room_id: number;
    start_time: string;
    end_time: string;
    status: string;
    description?: string;
    // patient: { id: number; first_name: string; last_name: string };
    // doctor: { id: number; first_name: string; last_name: string };
    // room: { id: number; name: string };
    created_at: string;
    updated_at?: string;
};

type Room = {
    id: number;
    name: string;
    description: string;
    area_id: number;
    area: { id: number; name: string };
    created_at: string;
    deleted_at?: string;
};

type Doctor = {
    id: number;
    first_name: string;
    last_name: string;
    email: string;
    phone?: string;
    created_at: Date;
    updated_at?: Date;
    deleted_at?: Date;
};

type Patient = {
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

const API_URL = '/api/appointments';
const API_PATIENTS_URL = '/api/patients';
const API_DOCTORS_URL = '/api/doctors';
const API_ROOMS_URL = '/api/rooms';

let currentEditingData: ResourceDataType | null = null;
const form = document.getElementById('resourceForm') as HTMLFormElement;
const modalElement = document.getElementById('addResourceModal')!;
const patientSelect = document.getElementById('inputPatient') as HTMLSelectElement;
const doctorSelect = document.getElementById('inputDoctor') as HTMLSelectElement;
const roomSelect = document.getElementById('inputRoom') as HTMLSelectElement;
let modal: Modal = {} as Modal;

const patients: Patient[] = [];
const rooms: Room[] = [];
const doctors: Doctor[] = [];

document.addEventListener('DOMContentLoaded', async () => {
    modal = new Modal(modalElement, { keyboard: false, backdrop: false });

    await loadPatients();
    await loadDoctors();
    await loadRooms();

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
            lengthMenu: 'Showing _MENU_ appointments',
            zeroRecords: 'No appointments found',
            emptyTable: 'No appointments available in this table',
            info: 'Showing appointments from _START_ to _END_ (of _TOTAL_)',
            infoEmpty: 'Empty table',
            infoFiltered: '',
            search: 'Search:',
            loadingRecords: 'Loading...',
        },
        columns: [
            {
                data: null,
                title: 'Patient',
                render: (data: ResourceDataType) => {
                    const patient = patients.find((p) => p.id === data.patient_id);
                    return patient ? `${patient.first_name} ${patient.last_name}` : 'N/A';
                },
            },
            {
                title: 'Doctor',
                data: null,
                render: (data: ResourceDataType) => {
                    const doctor = doctors.find((d) => d.id === data.doctor_id);
                    return doctor ? `${doctor.first_name} ${doctor.last_name}` : 'N/A';
                },
            },
            {
                title: 'Room',
                data: null,
                render: (data: ResourceDataType) => {
                    const room = rooms.find((r) => r.id === r.id);
                    return room ? room.name : 'N/A';
                },
            },
            {
                data: 'start_time',
                render: (data: string) => new Date(data).toLocaleString(),
            },
            {
                data: 'end_time',
                render: (data: string) => new Date(data).toLocaleString(),
            },
            {
                data: 'status',
                render: (data: string) => {
                    const statusMap: { [key: string]: string } = {
                        scheduled: '<span class="badge bg-warning">Scheduled</span>',
                        confirmed: '<span class="badge bg-info">Confirmed</span>',
                        completed: '<span class="badge bg-success">Completed</span>',
                        canceled: '<span class="badge bg-danger">Canceled</span>',
                    };
                    return statusMap[data] || data;
                },
            },
            {
                data: 'description',
                defaultContent: '',
                render: (data: string) => data || 'N/A',
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
                            <li><button id="deleteButton" class="dropdown-item">Cancel Appointment</button></li>
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
                addButton.innerHTML = 'Add Appointment';
                return addButton;
            },
        },
    });
}

async function loadPatients() {
    try {
        const response = await fetch(API_PATIENTS_URL);
        if (!response.ok) {
            throw new Error('Failed to fetch patients');
        }

        const { data } = await response.json();

        patients.push(...data);

        patientSelect.innerHTML = '<option value="" selected disabled>Choose a patient...</option>';

        data.forEach((patient: { id: number; first_name: string; last_name: string }) => {
            const option = document.createElement('option');
            option.value = patient.id.toString();
            option.textContent = `${patient.first_name} ${patient.last_name}`;
            patientSelect.appendChild(option);
        });
    } catch (error) {
        console.error('Error loading patients:', error);
        showErrorModal('Failed to load patients');
    }
}

async function loadDoctors() {
    try {
        const response = await fetch(API_DOCTORS_URL);
        if (!response.ok) {
            throw new Error('Failed to fetch doctors');
        }

        const { data } = await response.json();

        doctors.push(...data);

        doctorSelect.innerHTML = '<option value="" selected disabled>Choose a doctor...</option>';

        data.forEach((doctor: { id: number; first_name: string; last_name: string }) => {
            const option = document.createElement('option');
            option.value = doctor.id.toString();
            option.textContent = `${doctor.first_name} ${doctor.last_name}`;
            doctorSelect.appendChild(option);
        });
    } catch (error) {
        console.error('Error loading doctors:', error);
        showErrorModal('Failed to load doctors');
    }
}

async function loadRooms() {
    try {
        const response = await fetch(API_ROOMS_URL);
        if (!response.ok) {
            throw new Error('Failed to fetch rooms');
        }

        const { data } = await response.json();

        rooms.push(...data);

        roomSelect.innerHTML = '<option value="" selected disabled>Choose a room...</option>';

        data.forEach((room: { id: number; name: string }) => {
            const option = document.createElement('option');
            option.value = room.id.toString();
            option.textContent = room.name;
            roomSelect.appendChild(option);
        });
    } catch (error) {
        console.error('Error loading rooms:', error);
        showErrorModal('Failed to load rooms');
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
    });
}

async function handleFormSubmit(datatable: Api<ResourceDataType>) {
    const patientInput = document.getElementById('inputPatient') as HTMLSelectElement;
    const doctorInput = document.getElementById('inputDoctor') as HTMLSelectElement;
    const roomInput = document.getElementById('inputRoom') as HTMLSelectElement;
    const statusInput = document.getElementById('inputStatus') as HTMLSelectElement;
    const startTimeInput = document.getElementById('inputStartTime') as HTMLInputElement;
    const endTimeInput = document.getElementById('inputEndTime') as HTMLInputElement;
    const descriptionInput = document.getElementById('inputDescription') as HTMLTextAreaElement;

    // Validate end time is after start time
    const startTime = new Date(startTimeInput.value);
    const endTime = new Date(endTimeInput.value);

    if (endTime <= startTime) {
        showErrorModal('End time must be after start time');
        return;
    }

    const newData = {
        patient_id: parseInt(patientInput.value),
        doctor_id: parseInt(doctorInput.value),
        room_id: parseInt(roomInput.value),
        status: statusInput.value,
        start_time: startTimeInput.value,
        end_time: endTimeInput.value,
        description: descriptionInput.value.trim() || undefined,
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
            throw new Error(data.message || 'Failed to save appointment');
        }

        datatable.ajax.reload();
        modal.hide();
        showSuccessModal(currentEditingData ? 'Appointment updated successfully' : 'Appointment created successfully');
        resetForm();
    } catch (error: any) {
        showErrorModal(error.message);
    }
}

function isDataUnchanged(newData: Partial<ResourceDataType>) {
    if (!currentEditingData) return false;

    return (
        newData.patient_id === currentEditingData.patient_id &&
        newData.doctor_id === currentEditingData.doctor_id &&
        newData.room_id === currentEditingData.room_id &&
        newData.status === currentEditingData.status &&
        newData.start_time === currentEditingData.start_time &&
        newData.end_time === currentEditingData.end_time &&
        newData.description === currentEditingData.description
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

    const patientInput = document.getElementById('inputPatient') as HTMLSelectElement;
    const doctorInput = document.getElementById('inputDoctor') as HTMLSelectElement;
    const roomInput = document.getElementById('inputRoom') as HTMLSelectElement;
    const statusInput = document.getElementById('inputStatus') as HTMLSelectElement;
    const startTimeInput = document.getElementById('inputStartTime') as HTMLInputElement;
    const endTimeInput = document.getElementById('inputEndTime') as HTMLInputElement;
    const descriptionInput = document.getElementById('inputDescription') as HTMLTextAreaElement;
    const modalTitle = document.getElementById('modalTitle') as HTMLElement;
    const addButton = document.getElementById('addButton') as HTMLButtonElement;

    patientInput.value = editedData.patient_id.toString();
    doctorInput.value = editedData.doctor_id.toString();
    roomInput.value = editedData.room_id.toString();
    statusInput.value = editedData.status;

    // Format date-time for datetime-local input
    const formatDateForInput = (dateString: string): string => {
        const date = new Date(dateString);
        return date.toISOString().slice(0, 16); // Format: YYYY-MM-DDTHH:MM
    };

    startTimeInput.value = formatDateForInput(editedData.start_time);
    endTimeInput.value = formatDateForInput(editedData.end_time);
    descriptionInput.value = editedData.description || '';

    modalTitle.textContent = 'Edit appointment';
    addButton.textContent = 'Update';

    modal.show();
}

function handleDeleteButtonClick(targetData: ResourceDataType, datatable: Api<ResourceDataType>) {
    const patient = patients.find((p) => p.id === targetData.patient_id);
    const doctor = doctors.find((d) => d.id === targetData.doctor_id);
    const room = rooms.find((r) => r.id === targetData.room_id);

    createQuestion({
        title: 'Cancel appointment',
        text: `Are you sure you want to cancel the appointment for ${patient ? patient.first_name : 'Unknown'} ${patient ? patient.last_name : ''} with Dr. ${doctor ? doctor.first_name : ''} ${doctor ? doctor.last_name : ''}?`,
        confirmButtonText: 'Yes, cancel it',
        cancelButtonText: 'No',
        confirmButtonColor: 'danger',
        afterConfirm: async () => {
            await deleteResource(targetData.id, datatable);
            showSuccessModal('Appointment cancelled successfully');
        },
    });
}

async function deleteResource(dataId: number, datatable: Api<ResourceDataType>) {
    const response = await fetch(`${API_URL}/${dataId}`, {
        method: 'DELETE',
    });

    if (!response.ok) {
        const data = await response.json();
        throw new Error(data.message || 'Failed to cancel appointment');
    }

    datatable.ajax.reload();
}

function resetForm() {
    const patientInput = document.getElementById('inputPatient') as HTMLSelectElement;
    const doctorInput = document.getElementById('inputDoctor') as HTMLSelectElement;
    const roomInput = document.getElementById('inputRoom') as HTMLSelectElement;
    const statusInput = document.getElementById('inputStatus') as HTMLSelectElement;
    const startTimeInput = document.getElementById('inputStartTime') as HTMLInputElement;
    const endTimeInput = document.getElementById('inputEndTime') as HTMLInputElement;
    const descriptionInput = document.getElementById('inputDescription') as HTMLTextAreaElement;
    const modalTitle = document.getElementById('modalTitle') as HTMLElement;
    const addButton = document.getElementById('addButton') as HTMLButtonElement;

    patientInput.value = '';
    doctorInput.value = '';
    roomInput.value = '';
    statusInput.value = 'scheduled';
    startTimeInput.value = '';
    endTimeInput.value = '';
    descriptionInput.value = '';

    modalTitle.textContent = 'Add an appointment';
    addButton.textContent = 'Save';

    form.classList.remove('was-validated');
}
