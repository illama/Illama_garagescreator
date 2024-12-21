let garagePos = null;
let spawnPos = null;
let grades = [];
let isVisible = false;

// Gestion des événements de l'interface
window.addEventListener('message', function(event) {
    switch(event.data.type) {
        case 'openUI':
            document.body.style.display = 'block';
            isVisible = true;
            resetForm();
            break;
            
        case 'hideUI':
            document.body.style.display = 'none';
            isVisible = false;
            break;
            
        case 'showUI':
            document.body.style.display = 'block';
            isVisible = true;
            if (event.data.positionType && event.data.position) {
                if (event.data.positionType === 'garage') {
                    garagePos = event.data.position;
                    updatePositionDisplay('garage', event.data.position);
                } else {
                    spawnPos = event.data.position;
                    updatePositionDisplay('spawn', event.data.position);
                }
            }
            break;
    }
});

// Gestion des grades
function addGrade() {
    const gradeInput = document.getElementById('gradeInput');
    const grade = parseInt(gradeInput.value);
    
    if (isNaN(grade) || grade < 0) {
        alert('Veuillez entrer un numéro de grade valide (0 ou plus)');
        return;
    }
    
    if (grades.includes(grade)) {
        alert('Ce grade est déjà dans la liste');
        return;
    }
    
    grades.push(grade);
    updateGradesList();
    gradeInput.value = '';
}

function updateGradesList() {
    const gradesList = document.getElementById('gradesList');
    gradesList.innerHTML = '';
    
    grades.sort((a, b) => a - b).forEach(grade => {
        const gradeItem = document.createElement('div');
        gradeItem.className = 'grade-item';
        gradeItem.innerHTML = `
            <span>Grade ${grade}</span>
            <button onclick="removeGrade(${grade})" class="remove-btn">×</button>
        `;
        gradesList.appendChild(gradeItem);
    });
}

function removeGrade(grade) {
    grades = grades.filter(g => g !== grade);
    updateGradesList();
}

// Gestion des véhicules
function addVehicle() {
    const vehicleList = document.getElementById('vehicleList');
    const vehicleItem = document.createElement('div');
    vehicleItem.className = 'vehicle-item';
    vehicleItem.innerHTML = `
        <input type="text" placeholder="Nom du modèle (exemple: police)" class="vehicle-model" required>
        <input type="text" placeholder="Nom affiché" class="vehicle-label" required>
        <button onclick="removeVehicle(this)" class="remove-btn">Supprimer</button>
    `;
    vehicleList.appendChild(vehicleItem);
}

function removeVehicle(button) {
    button.parentElement.remove();
}

// Gestion des positions
function setGaragePosition() {
    fetch(`https://${GetParentResourceName()}/requestPosition`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type: 'garage' })
    });
}

function setSpawnPosition() {
    fetch(`https://${GetParentResourceName()}/requestPosition`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type: 'spawn' })
    });
}

function updatePositionDisplay(type, position) {
    const container = document.getElementById(`${type}Position`);
    const span = container.querySelector('span');
    span.textContent = `Position ${type === 'garage' ? 'du garage' : 'de spawn'}: X: ${position.x.toFixed(2)}, Y: ${position.y.toFixed(2)}, Z: ${position.z.toFixed(2)}${type === 'spawn' ? `, Direction: ${position.heading.toFixed(2)}°` : ''}`;
}

// Sauvegarde et fermeture
function saveGarage() {
    const name = document.getElementById('garageName').value;
    const job = document.getElementById('jobName').value;
    
    // Validation des champs obligatoires
    if (!name || !job) {
        alert('Veuillez remplir le nom du garage et le job');
        return;
    }
    
    if (grades.length === 0) {
        alert('Veuillez ajouter au moins un grade');
        return;
    }
    
    // Récupération des véhicules
    const vehicles = [];
    document.querySelectorAll('.vehicle-item').forEach(item => {
        const model = item.querySelector('.vehicle-model').value;
        const label = item.querySelector('.vehicle-label').value;
        
        if (!model || !label) {
            alert('Veuillez remplir tous les champs des véhicules');
            return;
        }
        
        vehicles.push({ model, label });
    });
    
    if (vehicles.length === 0) {
        alert('Veuillez ajouter au moins un véhicule');
        return;
    }
    
    // Création de l'objet de données
    const data = {
        name: name,
        job: job,
        grades: grades,
        vehicles: vehicles
    };
    
    // Envoi au serveur
    fetch(`https://${GetParentResourceName()}/saveGarage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).then(() => closeUI());
}

function closeUI() {
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    document.body.style.display = 'none';
    isVisible = false;
    resetForm();
}

function resetForm() {
    document.getElementById('garageName').value = '';
    document.getElementById('jobName').value = '';
    document.getElementById('gradeInput').value = '';
    document.getElementById('vehicleList').innerHTML = '';
    document.getElementById('gradesList').innerHTML = '';
    garagePos = null;
    spawnPos = null;
    grades = [];
    updatePositionDisplay('garage', { x: 0, y: 0, z: 0 });
    updatePositionDisplay('spawn', { x: 0, y: 0, z: 0, heading: 0 });
}

// Gestion des touches
document.addEventListener('keyup', function(event) {
    if (event.key === 'Escape' && isVisible) {
        closeUI();
    }
});