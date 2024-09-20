import type { IUserData } from '@interfaces/userData';

const rawUserData = localStorage.getItem('user_data');
if (!rawUserData) {
    window.location.href = '/login';

    throw new Error('User data not found in local storage');
}
export const currentUser: IUserData = JSON.parse(rawUserData);
