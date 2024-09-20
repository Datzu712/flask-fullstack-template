export interface IUserData {
    id: string;
    email: string;
    username: string;
    admin: string; // endpoints are protected so if u change this to boolean, u can only see some hidden options in the menu and other stuff, but they won't work
}
