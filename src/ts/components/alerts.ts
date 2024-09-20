export interface AlertOptions {
    message: string;
    type: 'primary' | 'secondary' | 'success' | 'danger' | 'warning' | 'info' | 'light' | 'dark';
    timeout?: number;
}

export class BasicAlert {
    private element: HTMLElement;
    constructor(el: HTMLElement | string) {
        const element = typeof el === 'string' ? document.getElementById(el) : el;
        if (!element) {
            throw new Error('Element not found');
        }
        this.element = element;
    }

    /**
     * Display an alert message
     * @param { object } options - The options object
     * @param { string } options.message - The message to display
     * @param { string } options.type - The type of alert to display (bootstrap alert type)
     * @param { number } options.timeout - The time in milliseconds before the alert is removed
     */
    public displayMessage({ message, type, timeout = 5000 }: AlertOptions) {
        const alert = document.createElement('div');
        alert.classList.add('alert', `alert-${type}`, 'alert-dismissible', 'fade', 'show');
        alert.setAttribute('role', 'alert');

        alert.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        `;
        this.element.appendChild(alert);

        setTimeout(() => {
            alert.remove();
        }, timeout);
    }
}
