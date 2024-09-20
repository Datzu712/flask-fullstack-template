import 'datatables.net-bs5/css/dataTables.bootstrap5.css';
import 'datatables.net-responsive-bs5';
import 'datatables.net-fixedheader-bs5';

import DataTable from 'datatables.net-bs5';
import moment from 'moment';
import { createQuestion, showErrorModal, showSuccessModal } from '../../components/modals';
import { currentUser } from '../main';

import type { Api } from 'datatables.net';
import { IUserData } from '@interfaces/userData';

document.addEventListener('DOMContentLoaded', function () {
    const usersTable = initializeDataTable();

    document.querySelector('#users-dt tbody')!.addEventListener('click', function (event) {
        const target = event.target as HTMLElement;
        const row = usersTable.row(target.closest('tr')!).data() as IUserData;

        if (target.id === 'editButton') {
            handleEditUser(row);
        } else if (target.id === 'deleteButton') {
            handleDeleteUser(row);
        }
    });
});

function initializeDataTable(): Api<any> {
    return new DataTable('#users-dt', {
        ajax: {
            url: '/api/users',
            dataSrc: function (json) {
                return json;
            },
        },
        responsive: true,
        autoWidth: true,
        fixedHeader: true,
        columns: [
            { data: 'name' },
            { data: 'email' },
            {
                data: 'admin',
                render: function (data: number) {
                    return data === 1 ? 'Admin' : 'User';
                },
            },
            {
                data: 'created_at',
                render: function (data: string) {
                    return moment(data).format('YYYY-MM-DD HH:mm:ss');
                },
            },
            {
                data: 'updated_at',
                render: function (data: string) {
                    return moment(data).format('YYYY-MM-DD HH:mm:ss');
                },
            },
            {
                orderable: false,
                data: null,
                render: function () {
                    return `
                        <div class="btn-group">
                            <button class="btn btn-primary dropdown-toggle" data-bs-toggle="dropdown" aria-expanded="false">
                                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-list"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M9 6l11 0" /><path d="M9 12l11 0" /><path d="M9 18l11 0" /><path d="M5 6l0 .01" /><path d="M5 12l0 .01" /><path d="M5 18l0 .01" /></svg>
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end">
                                <li><button id="editButton" class="dropdown-item">Edit</button></li>
                                <li><button id="deleteButton" class="dropdown-item">Delete</button></li>
                            </ul>
                        </div>
                    `;
                },
                width: '1%',
            },
        ],
    });
}

function handleEditUser(user: IUserData) {
    console.log('Edit', user);
}

function handleDeleteUser(user: IUserData) {
    if (user.id === currentUser.id) {
        showErrorModal('You cannot delete yourself!', 'danger');
        return;
    }
    createQuestion({
        title: 'Are you sure?',
        text: `Are you sure you want to delete the user "${user.username}"? This action cannot be undone.`,
        confirmButtonText: "Yes, I'm sure",
        cancelButtonText: 'Cancel',
        confirmButtonColor: 'danger',
        afterConfirm: () => {
            fetch('/api/users/' + user.id, {
                method: 'DELETE',
            })
                .then((response) => {
                    if (response.status !== 200) {
                        response.json().then(({ message }) => {
                            showErrorModal(message, 'danger');
                        });
                        return;
                    }
                    showSuccessModal('Removed user successful!');
                })
                .catch((error) => {
                    console.error(error);
                });
        },
    });
}
