document.addEventListener('DOMContentLoaded', function() {
    const alertContainer = document.querySelector('#alert-placeholder');

    const headerSelectedColor = 'rgb(221, 226, 231)';
    const headerPointedColor = 'rgb(186, 196, 206)';
    let sortedAscOrder = false;

    // Shows alert messages
    function showAlert(message, type) {
        const classes = ['alert', 'alert-dismissible', 'fade', type];
        const alertNode = document.createElement('div');
        classes.forEach(item => alertNode.classList.add(item));
        alertNode.textContent = message;
        const alertBtn = document.createElement('button');
        alertBtn.classList.add('btn-close');
        alertBtn.setAttribute('type', 'button');
        alertBtn.setAttribute('data-bs-dismiss', 'alert');
        alertBtn.setAttribute('aria-label', 'Close');
        alertNode.appendChild(alertBtn);
        alertContainer.appendChild(alertNode);
        // To appear with fade effect. Adding elements to the DOM require some time.
        setTimeout(() => {
            alertNode.classList.add('show');
        }, 50);
        // Close alert by timeout.
        window.setTimeout(function() {
            const alert = new bootstrap.Alert(alertNode);
            alert.close();
        }, 4000);
    }

    // Checkboxes action. Enabling text inputs.
    function enableTextInput() {
        const word = this.id.replace('cb_', '');
        const inputTextId = 'text_' + word;
        const inputText = document.querySelector('#' + inputTextId);
        inputText.disabled = ! this.checked;
    }

    const checkboxes = document.querySelectorAll('input[type="checkbox"]');
    checkboxes.forEach (checkbox => {
        checkbox.addEventListener('change', enableTextInput);
    })

    // Sorting table
    const table = document.querySelector('#words-table');
    function sortTable(colIndex, table, tableHeaders) {
        const header = tableHeaders[colIndex];
        sortedAscOrder = (header.style.backgroundColor === headerSelectedColor) && ! sortedAscOrder;

        const rows = Array.from(table.rows).slice(1);
        rows.sort((a, b) => {
            const cellA = a.cells[colIndex].innerText;
            const cellB = b.cells[colIndex].innerText;

            return sortedAscOrder ? compare(cellA, cellB) : compare(cellB, cellA);
        });

        rows.forEach(row => table.appendChild(row));

        // Mark the header of sorted column
        Array.from(tableHeaders).forEach(header => header.style.backgroundColor = '');
        header.style.backgroundColor = headerSelectedColor;
    }

    function compare(a, b) {
        if (a === b) {
            return 0;
        }
        const aInt = parseInt(a);
        const bInt = parseInt(b);
        if (Number.isInteger(aInt) && Number.isInteger(bInt)) {
            // -1 allways bigger then any positive
            return aInt === -1 || bInt !== -1 && aInt > bInt ? 1 : -1;
        }
        return a.localeCompare(b);
    }

    const tableHeaders = table.tHead.rows[0].cells;
    // First and last columns are not sortable.
    Array.from(tableHeaders).slice(1, tableHeaders.length - 1).forEach((header, i) => {
        header.addEventListener('click', () => sortTable(i + 1, table, tableHeaders));
        header.addEventListener('mouseover', function() {
            if (this.style.backgroundColor === '') {
                this.style.backgroundColor = headerPointedColor;
            }
        });
        header.addEventListener('mouseleave', function() {
            if (this.style.backgroundColor === headerPointedColor) {
                this.style.backgroundColor = '';
            }
        });
    })

    // Submitting data. Button action
    const button = document.querySelector('#submitBtn');
    const fileNameInput = document.querySelector('#filenameInput');
    const decknameInput = document.querySelector('#decknameInput');
    const modelNameInput = document.querySelector('#modelSelection')
    const spinner = document.querySelector('#spinner')

    async function submitData(table) {
        button.disabled = true

        const requestData = {'filename': fileNameInput.value,
            'deckname': decknameInput.value,
            'modelname': modelNameInput.value
        };
        // Collect selected words
        const words = [];
        Array.from(table.rows).slice(1).forEach(row => {
            if (row.cells[0].firstChild.checked) {
                let word = {'front': row.cells[1].innerText, 'back' : row.cells[6].firstChild.value};
                words.push(word);
            }
        });
        requestData.words = words;
        spinner.classList.remove('visually-hidden')
        
        // Request to the backend
        fetch("/anki", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(requestData)
        })
        // Process response
        .then(response => {
            const contentType = response.headers.get("content-type");
            // When got JSON - Alarming
            if (contentType && contentType.indexOf("application/json") !== -1) {
                return response.json()
                .then(json => {
                    console.log(json.alert)
                    if ('alert' in json) {
                        showAlert(json.alert, 'alert-danger');
                        throw new Error(json.alert);
                    }});
            // When got BLOB
            } else {
                const header = response.headers.get('Content-Disposition');
                const parts = header.split(';');
                const filename = parts[1].split('=')[1];
                return Promise.all([filename, response.blob()])
                .then(([filename, blob]) => {
                    const url = window.URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.href = url;
                    a.download = filename;
                    document.body.appendChild(a);
                    a.click();
                    a.remove();
                    window.URL.revokeObjectURL(url);
                });
            }                        
        })
        .catch(error => {
            console.error(error);
        })
        .finally(() => {
            button.disabled = false
            spinner.classList.add('visually-hidden')
            console.log(this)
        })
    }

    // Submit Button action 
    button.addEventListener('click', () => submitData(table));

    // Disable button when filename not provided
    fileNameInput.addEventListener('input', function() {
        button.disabled = this.value.length === 0
    })
})