function displayAlert(message, type) {
    const alert = document.getElementById('errorModal');
    if (!alert) {
        console.error('Alert element not found');
        return;
    }
    alert.classList.remove('d-none');
    alert.classList.add(`alert-${type}`);
    alert.innerHTML = message;
    setTimeout(() => {
        alert.classList.add('d-none');
        alert.classList.remove(`alert-${type}`);
    }, 8000);
}
