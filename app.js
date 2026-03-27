// Firebase Configuration
const firebaseConfig = {
    apiKey: 'AIzaSyAEGn5CDWQNO_ug8lR2Mz2JQC0ES3gx-0Q',
    appId: '1:697988632641:web:f4fc41c98dcec79b3136c0',
    messagingSenderId: '697988632641',
    projectId: 'smart-waste-segregation-cc790',
    authDomain: 'smart-waste-segregation-cc790.firebaseapp.com',
    storageBucket: 'smart-waste-segregation-cc790.firebasestorage.app',
    measurementId: 'G-ZS8RXJ7PQN',
};

// Initialize Firebase
let firebaseApp, firestore;
try {
    // Check if Firebase is already initialized
    if (firebase.apps.length === 0) {
        firebaseApp = firebase.initializeApp(firebaseConfig);
    } else {
        firebaseApp = firebase.app();
    }
    firestore = firebase.firestore();
    console.log('Firebase initialized successfully');
} catch (e) {
    console.error('Firebase initialization failed:', e);
    firestore = null;
}

// App State
const appState = {
    currentScreen: 'home',
    selectedQuest: null,
    activeQuest: null,
    progress: 0,
    wrongItemsCount: 0,
    timeLeft: 20,
    questTimer: null,
    bgIndex: 0,
    clockTimer: null,
    bgTimer: null,
    regularTrashCount: 0,
    regularTrashType: null,
    regularTrashItems: [], // Array to track all items thrown in regular trash mode
    pendingFeedback: null, // { type, count, timestamp, isQuest }
    questItemsThrown: [], // Array to track all items thrown during quest
    trashPoints: { // Default points for each trash type
        plastic: 5.0,
        paper: 3.0,
        'single-stream': 4.0,
        mixed: 1.0
    },
    trashPointsConfigured: false // Flag to track if admin has configured trash points
};

// Quest Data - Now loaded from Firestore
let quests = [];

// Background gradients
const backgrounds = [
    ['#22C55E', '#38BDF8'],
    ['#38BDF8', '#22C55E'],
    ['rgba(34, 197, 94, 0.8)', 'rgba(56, 189, 248, 0.8)'],
    ['rgba(56, 189, 248, 0.8)', 'rgba(34, 197, 94, 0.8)'],
    ['#22C55E', '#38BDF8'],
];

// Icon mapping
function getIconForType(type) {
    const icons = {
        'plastic': '🧴',
        'paper': '📄',
        'mixed': '🗑️',
        'single-stream': '♻️',
    };
    return icons[type] || '🗑️';
}

// Initialize App
function init() {
    updateClock();
    appState.clockTimer = setInterval(updateClock, 1000);
    
    startBackgroundAnimation();
    
    // Home screen click handler
    document.getElementById('home-content').addEventListener('click', showMenu);
    
    // Menu button handlers
    document.querySelectorAll('.menu-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const action = e.target.getAttribute('data-action');
            if (!action) return;
            
            // Check if it's a trash type modal button by checking if the modal is visible
            const trashTypeModal = document.getElementById('trash-type-modal');
            if (trashTypeModal && trashTypeModal.classList.contains('show')) {
                handleTrashTypeAction(action);
            } else {
                handleMenuAction(action);
            }
        });
    });
    
    // Load quests from Firestore
    loadQuests();
    
    // Set up real-time listener for quests
    setupQuestsListener();
    
    // Load trash points configuration
    loadTrashPoints();
    
    // Set up real-time listener for trash points (to detect when admin configures them)
    setupTrashPointsListener();
    
    // Test Firebase connection
    testFirebaseConnection();
}

// Test Firebase Connection
async function testFirebaseConnection() {
    console.log('========================================');
    console.log('🔥 Firebase Connection Test');
    console.log('========================================');
    
    // Check if running from file:// protocol (won't work)
    if (window.location.protocol === 'file:') {
        console.error('🚫 ERROR: You are opening this HTML file directly from the file system.');
        console.error('   Firebase requires the page to be served via HTTP/HTTPS.');
        console.error('');
        console.error('   To fix this, serve the file using one of these methods:');
        console.error('   1. Python: python -m http.server 8000');
        console.error('   2. Node.js: npx serve .');
        console.error('   3. VS Code: Use "Live Server" extension');
        console.error('');
        console.error('   Then open: http://localhost:8000/kiosk.html');
        console.log('========================================');
        showSnackbar('Error: Open via HTTP server, not file://', true);
        return;
    }
    
    if (!firestore) {
        console.warn('⚠️ Firestore is not initialized. Data will only be saved to localStorage.');
        console.warn('   Check browser console for initialization errors.');
        console.log('========================================');
        return;
    }
    
    console.log('📍 Project ID:', firebaseConfig.projectId);
    console.log('📍 Collection: Trashbin Data');
    console.log('📍 Document: trash_data');
    
    try {
        // Try to read from Firestore to test connection
        const testDoc = await firestore.collection('Trashbin Data').doc('trash_data').get();
        console.log('✅ Firebase connection test successful!');
        console.log('   Document exists:', testDoc.exists);
        if (testDoc.exists) {
            const data = testDoc.data();
            console.log('   Current data:', data);
        } else {
            console.log('   Document will be created on first save');
        }
        console.log('========================================');
        console.log('✅ Ready to save data to Firestore!');
    } catch (e) {
        console.error('❌ Firebase connection test failed:', e);
        console.error('');
        console.error('Please check:');
        console.error('1. Firebase configuration is correct');
        console.error('2. Firestore security rules allow read/write');
        console.error('   - Go to Firebase Console > Firestore > Rules');
        console.error('   - For testing, use: allow read, write: if true;');
        console.error('3. Internet connection is active');
        console.error('4. Browser console for CORS or network errors');
        console.log('========================================');
    }
}

// Clock Update
function updateClock() {
    const now = new Date();
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    const dateText = `${days[now.getDay()]}, ${months[now.getMonth()]} ${now.getDate()}, ${now.getFullYear()}`;
    const timeText = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`;
    
    document.getElementById('date-text').textContent = dateText;
    document.getElementById('time-text').textContent = timeText;
}

// Background Animation
function startBackgroundAnimation() {
    updateBackground();
    appState.bgTimer = setInterval(() => {
        appState.bgIndex = (appState.bgIndex + 1) % backgrounds.length;
        updateBackground();
    }, 5000);
}

function updateBackground() {
    const bg = document.getElementById('animated-bg');
    const [color1, color2] = backgrounds[appState.bgIndex];
    bg.style.background = `linear-gradient(135deg, ${color1}, ${color2})`;
}

// Screen Management
function showScreen(screenId) {
    document.querySelectorAll('.screen').forEach(screen => {
        screen.classList.remove('active');
    });
    const screen = document.getElementById(`${screenId}-screen`);
    if (screen) {
        screen.classList.add('active');
        appState.currentScreen = screenId;
    }
}

function showModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('show');
    }
}

function hideModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('show');
    }
}

// Navigation
function goHome() {
    stopQuest();
    showScreen('home');
    hideModal('menu-modal');
    hideModal('completion-popup');
    hideModal('wrong-trash-modal');
    hideModal('reward-form-modal');
    appState.selectedQuest = null;
    editingRewardId = null;
}

function showMenu() {
    showModal('menu-modal');
}

function handleMenuAction(action) {
    hideModal('menu-modal');
    switch (action) {
        case 'insert-trash':
            showTrashTypeModal();
            break;
        case 'how-to-use':
            showScreen('how-to-use');
            break;
        case 'admin-rewards':
            showScreen('admin-rewards');
            loadRewards();
            break;
        case 'home':
            goHome();
            break;
    }
}

function showInsertTrash() {
    // Reload quests when showing insert trash screen
    loadQuests();
    showScreen('insert-trash');
}

// Trash Type Selection Modal
function showTrashTypeModal() {
    showModal('trash-type-modal');
}

function hideTrashTypeModal() {
    hideModal('trash-type-modal');
}

function handleTrashTypeAction(action) {
    hideTrashTypeModal();
    switch (action) {
        case 'regular-trash':
            startRegularTrash();
            break;
        case 'trash-with-points':
            showScreen('insert-trash');
            break;
    }
}

// Regular Trash Functions
function startRegularTrash() {
    appState.regularTrashCount = 0;
    appState.regularTrashType = null;
    appState.regularTrashItems = []; // Reset items array
    hideModal('trash-type-modal');
    hideModal('menu-modal');
    showScreen('regular-trash');
    updateRegularTrashUI();
}

function addRegularTrash(type) {
    appState.regularTrashCount++;
    appState.regularTrashItems.push(type); // Track each item
    
    // Set or update trash type for display
    if (!appState.regularTrashType) {
        appState.regularTrashType = type;
    } else if (appState.regularTrashType !== type) {
        // If different type is added, mark as mixed
        appState.regularTrashType = 'mixed';
    }
    
    updateRegularTrashUI();
    showSnackbar('Trash added!');
}

function updateRegularTrashUI() {
    document.getElementById('trash-count-text').textContent = appState.regularTrashCount;
    
    const typeDisplay = document.getElementById('trash-type-display');
    if (appState.regularTrashCount === 0) {
        typeDisplay.innerHTML = '<span class="trash-type-text">No trash thrown yet</span>';
    } else {
        const typeNames = {
            'plastic': 'Plastic Bottle',
            'paper': 'Paper',
            'single-stream': 'Single Stream',
            'mixed': 'Mixed'
        };
        const typeName = typeNames[appState.regularTrashType] || 'Unknown';
        typeDisplay.innerHTML = `
            <span class="trash-type-text">${typeName}</span>
            <span class="trash-type-icon">${getIconForType(appState.regularTrashType)}</span>
        `;
    }
}

async function finishRegularTrash() {
    if (appState.regularTrashCount === 0) {
        showSnackbar('Please throw at least one trash item', true);
        return;
    }
    
    // Save to Firebase/localStorage for each type
    const now = new Date();
    
    // Count items by type for saving to Firestore
    const typeCounts = {};
    appState.regularTrashItems.forEach(type => {
        typeCounts[type] = (typeCounts[type] || 0) + 1;
    });
    
    // Save each type separately to Firestore
    for (const [type, count] of Object.entries(typeCounts)) {
        await saveKioskRecord(type, count, now);
    }
    
    // Store feedback data with all items thrown
    appState.pendingFeedback = {
        itemsThrown: [...appState.regularTrashItems], // Copy of all items
        timestamp: now,
        isQuest: false
    };
    
    showFeedbackModal();
}

function cancelRegularTrash() {
    appState.regularTrashCount = 0;
    appState.regularTrashType = null;
    appState.regularTrashItems = [];
    goHome();
}

// Load Quests from Firestore
async function loadQuests() {
    if (!firestore) {
        console.warn('Firestore not initialized - no quests will be loaded');
        quests = [];
        renderQuests();
        return;
    }
    
    try {
        const questsRef = firestore.collection('Quests Data');
        // Get all quests and filter by platform on client side (more flexible)
        const snapshot = await questsRef.get();
        
        quests = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            const platform = data.platform || 'both';
            // Only include quests for kiosk or both platforms
            if (platform === 'kiosk' || platform === 'both') {
                quests.push({
                    id: doc.id,
                    type: data.type || 'mixed',
                    target: data.target || 1,
                    title: data.title || data.name || 'Quest',
                    desc: data.desc || data.description || '',
                    reward: data.reward || data.name || 'Reward',
                });
            }
        });
        
        console.log(`Loaded ${quests.length} quest(s) from Firestore`);
        renderQuests();
    } catch (error) {
        console.error('Error loading quests:', error);
        showSnackbar('Failed to load quests', true);
        quests = [];
        renderQuests();
    }
}

// Set up real-time listener for quests
function setupQuestsListener() {
    if (!firestore) {
        console.warn('Firestore not initialized - real-time quest updates disabled');
        return;
    }
    
    try {
        const questsRef = firestore.collection('Quests Data');
        // Listen to all quests and filter by platform on client side
        questsRef.onSnapshot((snapshot) => {
            quests = [];
            snapshot.forEach(doc => {
                const data = doc.data();
                const platform = data.platform || 'both';
                // Only include quests for kiosk or both platforms
                if (platform === 'kiosk' || platform === 'both') {
                    quests.push({
                        id: doc.id,
                        type: data.type || 'mixed',
                        target: data.target || 1,
                        title: data.title || data.name || 'Quest',
                        desc: data.desc || data.description || '',
                        reward: data.reward || data.name || 'Reward',
                    });
                }
            });
            
            console.log(`Quests updated: ${quests.length} quest(s) available`);
            renderQuests();
        }, (error) => {
            console.error('Error listening to quests:', error);
        });
    } catch (error) {
        console.error('Error setting up quests listener:', error);
    }
}

// Render Quests
function renderQuests() {
    const grid = document.getElementById('quests-grid');
    grid.innerHTML = '';
    
    if (quests.length === 0) {
        grid.innerHTML = `
            <div style="grid-column: 1 / -1; text-align: center; padding: 60px 20px; color: #666;">
                <div style="font-size: 48px; margin-bottom: 16px;">📋</div>
                <h3 style="margin: 0 0 8px 0; color: #333;">No Quests Available</h3>
                <p style="margin: 0; font-size: 16px;">Please wait for an admin to create quests/rewards for the kiosk.</p>
            </div>
        `;
        return;
    }
    
    quests.forEach(quest => {
        const card = document.createElement('div');
        card.className = 'quest-card';
        if (appState.selectedQuest?.id === quest.id) {
            card.classList.add('selected');
        }
        card.innerHTML = `
            <div class="quest-icon">${getIconForType(quest.type)}</div>
            <div class="quest-title">${quest.title}</div>
            <div class="quest-desc">${quest.desc}</div>
            <div class="reward-badge">${quest.reward}</div>
        `;
        card.addEventListener('click', () => showTaskSelection(quest));
        grid.appendChild(card);
    });
}

// Task Selection
function showTaskSelection(quest) {
    appState.selectedQuest = quest;
    renderQuests();
    
    document.getElementById('selected-quest-icon').textContent = getIconForType(quest.type);
    document.getElementById('selected-quest-title').textContent = quest.title;
    document.getElementById('selected-quest-desc').textContent = quest.desc;
    document.getElementById('selected-quest-reward').textContent = quest.reward;
    document.getElementById('selected-quest-target').textContent = `${quest.target} items`;
    document.getElementById('selected-quest-reward-text').textContent = quest.reward;
    
    showScreen('task-selection');
}

function startQuest() {
    if (!appState.selectedQuest) return;
    
    appState.activeQuest = appState.selectedQuest;
    appState.progress = 0;
    appState.wrongItemsCount = 0;
    appState.timeLeft = 20;
    
    showScreen('active-quest');
    updateQuestUI();
    
    // Start timer
    if (appState.questTimer) {
        clearInterval(appState.questTimer);
    }
    
    appState.questTimer = setInterval(() => {
        if (appState.timeLeft <= 1) {
            clearInterval(appState.questTimer);
            questTimeout();
            return;
        }
        appState.timeLeft--;
        updateQuestUI();
    }, 1000);
}

function stopQuest() {
    if (appState.questTimer) {
        clearInterval(appState.questTimer);
        appState.questTimer = null;
    }
    appState.activeQuest = null;
    appState.progress = 0;
    appState.wrongItemsCount = 0;
    appState.questItemsThrown = []; // Reset items thrown array
}

function questTimeout() {
    if (appState.wrongItemsCount > 0) {
        showModal('wrong-trash-modal');
    } else {
        stopQuest();
        goHome();
    }
}

function updateQuestUI() {
    if (!appState.activeQuest) return;
    
    document.getElementById('timer-text').textContent = appState.timeLeft;
    document.getElementById('progress-text').textContent = `${appState.progress} / ${appState.activeQuest.target} items inserted`;
    
    const progressPct = Math.min((appState.progress / appState.activeQuest.target) * 100, 100);
    document.getElementById('progress-fill').style.width = `${progressPct}%`;
}

// Add Item
async function addItem(type) {
    if (!appState.activeQuest) return;
    
    const now = new Date();
    
    // Track this item in the quest items array
    appState.questItemsThrown.push(type);
    
    if (type !== appState.activeQuest.type) {
        appState.progress++;
        appState.wrongItemsCount++;
        showSnackbar('Wrong item type!', true);
        
        // Save to Firebase/localStorage
        await saveKioskRecord(type, 1, now);
        
        // Pause timer while feedback and wrong trash modal are shown
        const wasTimerRunning = appState.questTimer !== null;
        if (wasTimerRunning && appState.questTimer) {
            clearInterval(appState.questTimer);
            appState.questTimer = null;
        }
        
        // Store feedback data with all items thrown
        appState.pendingFeedback = {
            itemsThrown: [...appState.questItemsThrown], // Copy of all items
            timestamp: now,
            isQuest: true,
            expectedType: appState.activeQuest.type,
            resumeTimer: wasTimerRunning,
            showWrongTrashAfterFeedback: true
        };
        
        // Show feedback modal - wrong trash modal will show after feedback
        showFeedbackModal();
    } else {
        appState.progress++;
        showSnackbar('Correct item added!');
        
        // Save to Firebase/localStorage
        await saveKioskRecord(type, 1, now);
        
        // Check if quest is completed
        if (appState.progress >= appState.activeQuest.target) {
            // Quest completed - pause timer and show feedback
            if (appState.questTimer) {
                clearInterval(appState.questTimer);
                appState.questTimer = null;
            }
            
            // Store feedback data with all items thrown
            appState.pendingFeedback = {
                itemsThrown: [...appState.questItemsThrown], // Copy of all items
                timestamp: now,
                isQuest: true,
                expectedType: appState.activeQuest.type,
                showCompletionAfterFeedback: true,
                resumeTimer: false
            };
            
            // Show feedback modal - completion popup will show after feedback
            showFeedbackModal();
        }
    }
    
    updateQuestUI();
}

// Save Kiosk Record
async function saveKioskRecord(type, items, timestamp) {
    // Try Firebase first
    if (firestore) {
        try {
            const firestoreType = getFirestoreType(type);
            // Use the same collection and document ID as Flutter app
            const docRef = firestore.collection('Trashbin Data').doc('trash_data');
            
            console.log(`Attempting to save: ${items} ${type} item(s) as ${firestoreType} to Firestore...`);
            
            // Use FieldValue.increment() for atomic updates - same as Flutter app
            // This is the proper way to increment values in Firestore
            const updateData = {};
            updateData[firestoreType] = firebase.firestore.FieldValue.increment(items);
            
            await docRef.set(updateData, { merge: true });
            console.log(`✅ Successfully incremented ${firestoreType} by ${items} using atomic operation`);
            
            // Optional: Verify the save by reading back (for debugging)
            try {
                const savedDoc = await docRef.get();
                if (savedDoc.exists) {
                    const data = savedDoc.data();
                    console.log(`✅ Verified! Current Firestore data:`, data);
                }
            } catch (verifyError) {
                console.warn('Could not verify save (read permission may be restricted):', verifyError);
            }
        } catch (e) {
            console.error('❌ Firebase save failed:', e);
            console.error('Error details:', {
                code: e.code,
                message: e.message,
                stack: e.stack
            });
            
            // Common error handling with helpful messages
            if (e.code === 'permission-denied') {
                console.error('🔒 PERMISSION DENIED: Update your Firestore security rules to allow writes.');
                console.error('   Go to Firebase Console > Firestore Database > Rules');
                console.error('   For testing, you can use: allow read, write: if true;');
            } else if (e.message && e.message.includes('network')) {
                console.error('🌐 NETWORK ERROR: Check your internet connection.');
            } else if (e.message && e.message.includes('CORS')) {
                console.error('🚫 CORS ERROR: You must serve this HTML file through an HTTP server.');
                console.error('   Run: python -m http.server 8000');
                console.error('   Or: npx serve .');
                console.error('   Then open: http://localhost:8000/kiosk.html');
            }
            
            // Show error to user
            showSnackbar('Failed to save to database', true);
        }
    } else {
        console.warn('⚠️ Firestore not initialized - data will only be saved to localStorage');
        console.warn('   Make sure you are serving this file through an HTTP server, not opening directly.');
    }
    
    // Also save to localStorage as backup
    try {
        const records = JSON.parse(localStorage.getItem('kiosk_records') || '[]');
        records.push({
            type,
            items,
            timestamp: timestamp.toISOString(),
        });
        localStorage.setItem('kiosk_records', JSON.stringify(records));
        console.log('✅ Saved to localStorage as backup');
    } catch (e) {
        console.warn('LocalStorage save failed:', e);
    }
}

function getFirestoreType(kioskType) {
    const mapping = {
        'plastic': 'Plastic',
        'paper': 'Paper',
        'single-stream': 'Single-stream',
        'mixed': 'Mixed',
    };
    return mapping[kioskType] || 'Mixed';
}

// Completion Popup
function showCompletionPopup() {
    showModal('completion-popup');
}

function hideCompletionPopup() {
    hideModal('completion-popup');
    goHome();
}

function printVoucher() {
    hideModal('completion-popup');
    showScreen('printing');
    
    setTimeout(() => {
        showScreen('thank-you');
        setTimeout(() => {
            goHome();
        }, 3000);
    }, 2000);
}

// Get and display reward code from Firestore
async function showRewardCode() {
    if (!firestore) {
        console.warn('⚠️ Firestore not initialized - cannot get reward code');
        // Show notification that codes are not available
        showNoCodesModal();
        return;
    }
    
    try {
        const codesRef = firestore.collection('Reward Codes');
        
        // Use a transaction to atomically get and reserve a code
        // This prevents race conditions where multiple users might get the same code
        const codeDoc = await firestore.runTransaction(async (transaction) => {
            // Get first available unredeemed and unassigned code
            const snapshot = await codesRef
                .where('isRedeemed', '==', false)
                .where('isAssigned', '==', false)
                .limit(1)
                .get();
            
            if (snapshot.empty) {
                return null;
            }
            
            const doc = snapshot.docs[0];
            const docRef = codesRef.doc(doc.id);
            const data = doc.data();
            
            // Check again within transaction to ensure it's still available
            const docSnapshot = await transaction.get(docRef);
            const docData = docSnapshot.data();
            if (!docSnapshot.exists || docData.isRedeemed || docData.isAssigned) {
                return null; // Code was already taken
            }
            
            // Mark code as assigned to prevent other kiosk users from getting it
            // The code is still valid for redemption in the mobile app
            transaction.update(docRef, {
                isAssigned: true,
                assignedAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
            });
            
            return { id: doc.id, code: data.code || '----', data: data };
        });
        
        if (!codeDoc) {
            console.warn('⚠️ No reward codes available in Firestore');
            // Show notification modal for no codes available
            showNoCodesModal();
            return;
        }
        
        console.log(`✅ Reward code retrieved and assigned: ${codeDoc.code}`);
        console.log(`   Code is now assigned and can be redeemed in the mobile app`);
        console.log(`   Points value: ${codeDoc.data.points || 0}`);
        
        // Display the code in the modal
        document.getElementById('reward-code-display').textContent = codeDoc.code;
        
        // Update modal text with points value
        const descElement = document.getElementById('reward-code-description');
        const points = codeDoc.data.points || 0;
        if (descElement) {
            descElement.textContent = `Congratulations! You earned ${points} points. Here is your 4-digit reward code:`;
        }
        
        showModal('reward-code-modal');
        
    } catch (error) {
        console.error('❌ Error getting reward code:', error);
        showSnackbar('Error getting reward code. Please try again.', true);
        // Still show completion popup as fallback
        showCompletionPopup();
    }
}

function closeRewardCodeModal() {
    hideModal('reward-code-modal');
    // After showing code, go home (for regular trash) or show completion popup (for quests)
    // Check if we're coming from regular trash by checking if regularTrashItems is empty
    if (appState.regularTrashItems.length === 0 && appState.regularTrashCount === 0) {
        // Regular trash - go home
        setTimeout(() => {
            goHome();
        }, 500);
    } else {
        // Quest - show completion popup for printing option
        showCompletionPopup();
    }
}

function showNoCodesModal() {
    showModal('no-codes-modal');
}

function closeNoCodesModal() {
    hideModal('no-codes-modal');
    // After showing notification, show completion popup for printing option
    showCompletionPopup();
}

// Show notification that points and codes are not ready
function showPointsNotReadyModal() {
    showModal('points-not-ready-modal');
}

function closePointsNotReadyModal() {
    hideModal('points-not-ready-modal');
    // Go home after showing notification
    setTimeout(() => {
        goHome();
    }, 500);
}

// Wrong Trash Message
function tryAgainQuest() {
    hideModal('wrong-trash-modal');
    
    // Reset quest progress and timer
    if (appState.activeQuest) {
        // Reset progress to zero
        appState.progress = 0;
        appState.wrongItemsCount = 0;
        appState.questItemsThrown = []; // Reset items thrown array
        
        // Reset timer to 20 seconds
        appState.timeLeft = 20;
        
        // Clear existing timer if running
        if (appState.questTimer) {
            clearInterval(appState.questTimer);
            appState.questTimer = null;
        }
        
        // Start timer again
        appState.questTimer = setInterval(() => {
            if (appState.timeLeft <= 1) {
                clearInterval(appState.questTimer);
                questTimeout();
                return;
            }
            appState.timeLeft--;
            updateQuestUI();
        }, 1000);
        
        // Update UI to show reset values
        updateQuestUI();
    } else {
        // No active quest, go back to quest section
        stopQuest();
        showInsertTrash();
    }
}

function backToQuestSection() {
    hideModal('wrong-trash-modal');
    stopQuest();
    showInsertTrash();
}

function backToHomeFromWrongTrash() {
    hideModal('wrong-trash-modal');
    stopQuest();
    goHome();
}

// Keep old function for backward compatibility (if used elsewhere)
function hideWrongTrashMessage() {
    tryAgainQuest();
}

// Snackbar
function showSnackbar(message, error = false) {
    const snackbar = document.getElementById('snackbar');
    snackbar.textContent = message;
    snackbar.className = `snackbar ${error ? 'error' : ''}`;
    snackbar.classList.add('show');
    
    setTimeout(() => {
        snackbar.classList.remove('show');
    }, 2000);
}

// Feedback Modal
function showFeedbackModal() {
    if (!appState.pendingFeedback) return;
    
    const feedback = appState.pendingFeedback;
    const infoDiv = document.getElementById('feedback-info');
    
    const typeNames = {
        'plastic': 'Plastic Bottle',
        'paper': 'Paper',
        'single-stream': 'Single Stream',
        'mixed': 'Mixed'
    };
    
    let infoHTML = '';
    
    if (feedback.isQuest && feedback.expectedType) {
        // For quests: Show expected type, total count, and all types user threw
        const expectedName = typeNames[feedback.expectedType] || 'Unknown';
        const expectedIcon = getIconForType(feedback.expectedType);
        
        // Get all items thrown
        const itemsThrown = feedback.itemsThrown || [];
        const totalCount = itemsThrown.length;
        
        // Count occurrences of each type
        const typeCounts = {};
        itemsThrown.forEach(type => {
            typeCounts[type] = (typeCounts[type] || 0) + 1;
        });
        
        // Build user throw display with all types
        const userThrownTypes = [];
        Object.keys(typeCounts).forEach(type => {
            const count = typeCounts[type];
            const typeName = typeNames[type] || 'Unknown';
            const icon = getIconForType(type);
            if (count === 1) {
                userThrownTypes.push(`${icon} ${typeName}`);
            } else {
                userThrownTypes.push(`${icon} ${typeName} (${count})`);
            }
        });
        
        const userThrownDisplay = userThrownTypes.length > 0 
            ? userThrownTypes.join(', ') 
            : 'None';
        
        infoHTML = `
            <p><strong>Type of trash:</strong> <span class="feedback-type">${expectedIcon} ${expectedName}</span></p>
            <p><strong>Number of trash:</strong> ${totalCount} item(s)</p>
            <p><strong>User throw:</strong> <span class="feedback-type">${userThrownDisplay}</span></p>
        `;
    } else {
        // For regular trash: Show type and count (no expected type)
        const itemsThrown = feedback.itemsThrown || [feedback.type];
        const totalCount = itemsThrown.length;
        
        // Count occurrences of each type
        const typeCounts = {};
        itemsThrown.forEach(type => {
            typeCounts[type] = (typeCounts[type] || 0) + 1;
        });
        
        // Build user throw display with all types
        const userThrownTypes = [];
        Object.keys(typeCounts).forEach(type => {
            const count = typeCounts[type];
            const typeName = typeNames[type] || 'Unknown';
            const icon = getIconForType(type);
            if (count === 1) {
                userThrownTypes.push(`${icon} ${typeName}`);
            } else {
                userThrownTypes.push(`${icon} ${typeName} (${count})`);
            }
        });
        
        const userThrownDisplay = userThrownTypes.length > 0 
            ? userThrownTypes.join(', ') 
            : 'None';
        
        infoHTML = `
            <p><strong>Type of trash:</strong> <span class="feedback-type">${userThrownDisplay}</span></p>
            <p><strong>Number of trash:</strong> ${totalCount} item(s)</p>
            <p><strong>User throw:</strong> <span class="feedback-type">${userThrownDisplay}</span></p>
        `;
    }
    
    infoDiv.innerHTML = infoHTML;
    showModal('feedback-modal');
}

async function submitFeedback(isCorrect) {
    if (!appState.pendingFeedback) {
        hideModal('feedback-modal');
        return;
    }
    
    const feedback = appState.pendingFeedback;
    
    // Get items thrown array or fallback to single type/count
    let itemsThrown = feedback.itemsThrown;
    if (!itemsThrown && feedback.type) {
        // Fallback for old structure or regular trash
        itemsThrown = [];
        const count = feedback.count || 1;
        for (let i = 0; i < count; i++) {
            itemsThrown.push(feedback.type);
        }
    }
    itemsThrown = itemsThrown || [];
    const totalCount = itemsThrown.length;
    
    // Count occurrences of each type for Firestore
    const typeCounts = {};
    itemsThrown.forEach(type => {
        typeCounts[type] = (typeCounts[type] || 0) + 1;
    });
    
    // Save feedback to Firestore
    await saveFeedbackToFirestore({
        itemsThrown: itemsThrown,
        typeCounts: typeCounts,
        totalCount: totalCount,
        timestamp: feedback.timestamp,
        isQuest: feedback.isQuest,
        isCorrect: isCorrect,
        expectedType: feedback.expectedType || null
    });
    
    hideModal('feedback-modal');
    
    // Reset pending feedback
    const showCompletion = feedback.showCompletionAfterFeedback;
    const resumeTimer = feedback.resumeTimer;
    const showWrongTrash = feedback.showWrongTrashAfterFeedback;
    appState.pendingFeedback = null;
    
    // If quest was completed, get reward code and show it after feedback
    if (showCompletion) {
        // Get and display reward code from Firestore
        await showRewardCode();
    } else if (showWrongTrash) {
        // Show wrong trash modal after feedback (with small delay to ensure feedback modal is closed)
        setTimeout(() => {
            showModal('wrong-trash-modal');
        }, 300);
    } else if (!feedback.isQuest) {
        // Regular trash - calculate points, generate code, and show it
        await handleRegularTrashCompletion(feedback, itemsThrown, typeCounts);
    } else if (resumeTimer && appState.activeQuest) {
        // Resume quest timer
        appState.questTimer = setInterval(() => {
            if (appState.timeLeft <= 1) {
                clearInterval(appState.questTimer);
                questTimeout();
                return;
            }
            appState.timeLeft--;
            updateQuestUI();
        }, 1000);
    }
}

async function saveFeedbackToFirestore(feedbackData) {
    if (!firestore) {
        console.warn('⚠️ Firestore not initialized - feedback will only be saved to localStorage');
        // Save to localStorage as backup
        try {
            const feedbacks = JSON.parse(localStorage.getItem('kiosk_feedbacks') || '[]');
            feedbacks.push({
                ...feedbackData,
                timestamp: feedbackData.timestamp.toISOString()
            });
            localStorage.setItem('kiosk_feedbacks', JSON.stringify(feedbacks));
            console.log('✅ Saved feedback to localStorage as backup');
        } catch (e) {
            console.warn('LocalStorage save failed:', e);
        }
        return;
    }
    
    try {
        const feedbackCollection = firestore.collection('Trash Confirmation Feedback');
        
        const feedbackDoc = {
            itemsThrown: feedbackData.itemsThrown || [],
            typeCounts: feedbackData.typeCounts || {},
            totalCount: feedbackData.totalCount || 0,
            timestamp: firebase.firestore.Timestamp.fromDate(feedbackData.timestamp),
            isQuest: feedbackData.isQuest,
            isCorrect: feedbackData.isCorrect,
            expectedType: feedbackData.expectedType,
            createdAt: firebase.firestore.FieldValue.serverTimestamp()
        };
        
        // Also include legacy fields for backward compatibility
        if (feedbackData.itemsThrown && feedbackData.itemsThrown.length > 0) {
            feedbackDoc.type = feedbackData.itemsThrown[0]; // First item as primary type
            feedbackDoc.count = feedbackData.totalCount;
        }
        
        const docRef = await feedbackCollection.add(feedbackDoc);
        console.log('✅ Successfully saved feedback to Firestore');
        console.log('📄 Collection: Trash Confirmation Feedback');
        console.log('📄 Document ID:', docRef.id);
        console.log('📄 Full path: Trash Confirmation Feedback/' + docRef.id);
        showSnackbar('Thank you for your feedback!');
    } catch (e) {
        console.error('❌ Failed to save feedback to Firestore:', e);
        showSnackbar('Failed to save feedback', true);
        
        // Save to localStorage as backup
        try {
            const feedbacks = JSON.parse(localStorage.getItem('kiosk_feedbacks') || '[]');
            feedbacks.push({
                ...feedbackData,
                timestamp: feedbackData.timestamp.toISOString()
            });
            localStorage.setItem('kiosk_feedbacks', JSON.stringify(feedbacks));
            console.log('✅ Saved feedback to localStorage as backup');
        } catch (localError) {
            console.warn('LocalStorage save failed:', localError);
        }
    }
}

// Reward Management Functions
let editingRewardId = null;

async function loadRewards() {
    if (!firestore) {
        console.error('Firestore not initialized');
        return;
    }
    
    try {
        const rewardsRef = firestore.collection('Mobile App Rewards Data');
        const snapshot = await rewardsRef.orderBy('createdAt', 'desc').get();
        
        const rewardsList = document.getElementById('rewards-list');
        rewardsList.innerHTML = '';
        
        if (snapshot.empty) {
            rewardsList.innerHTML = '<p style="text-align: center; color: #666; padding: 40px;">No rewards found. Click "Add" to create your first reward.</p>';
            return;
        }
        
        snapshot.forEach(doc => {
            const data = doc.data();
            const rewardCard = document.createElement('div');
            rewardCard.className = 'reward-card';
            rewardCard.style.cssText = 'background: white; border-radius: 12px; padding: 20px; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);';
            
            const platformBadge = data.platform === 'mobile' ? '📱 Mobile' : 
                                 data.platform === 'kiosk' ? '🖥️ Kiosk' : 
                                 '📱🖥️ Both';
            const platformColor = data.platform === 'mobile' ? '#2196F3' : 
                                 data.platform === 'kiosk' ? '#FF9800' : 
                                 '#4CAF50';
            
            rewardCard.innerHTML = `
                <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 12px;">
                    <h3 style="margin: 0; font-size: 20px; color: #333;">${data.name || 'Unnamed Reward'}</h3>
                    <span style="background: ${platformColor}15; color: ${platformColor}; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;">${platformBadge}</span>
                </div>
                <p style="color: #666; margin: 8px 0;">${data.description || 'No description'}</p>
                <div style="display: flex; gap: 16px; margin-top: 16px; flex-wrap: wrap;">
                    <div style="display: flex; align-items: center; gap: 4px;">
                        <span style="font-size: 18px;">⭐</span>
                        <span style="font-weight: 600; color: #FF9800;">${data.minimumRequirement || 0} points</span>
                    </div>
                    ${data.redeemCode ? `
                        <div style="display: flex; align-items: center; gap: 4px;">
                            <span style="font-size: 18px;">🎫</span>
                            <span style="font-weight: 600; color: #666;">Code: ${data.redeemCode}</span>
                        </div>
                    ` : ''}
                </div>
                <div style="display: flex; gap: 8px; margin-top: 16px;">
                    <button onclick="editReward('${doc.id}')" style="flex: 1; padding: 10px; background: #2196F3; color: white; border: none; border-radius: 8px; font-weight: 600; cursor: pointer;">Edit</button>
                    <button onclick="deleteReward('${doc.id}', '${data.name || 'this reward'}')" style="flex: 1; padding: 10px; background: #f44336; color: white; border: none; border-radius: 8px; font-weight: 600; cursor: pointer;">Delete</button>
                </div>
            `;
            
            rewardsList.appendChild(rewardCard);
        });
    } catch (error) {
        console.error('Error loading rewards:', error);
        showSnackbar('Failed to load rewards', true);
    }
}

function showAddRewardModal() {
    editingRewardId = null;
    document.getElementById('reward-form-title').textContent = 'Add New Reward';
    document.getElementById('reward-form').reset();
    document.getElementById('reward-platform').value = 'both';
    document.getElementById('reward-form-modal').classList.add('show');
}

function closeRewardFormModal() {
    document.getElementById('reward-form-modal').classList.remove('show');
    editingRewardId = null;
}

async function editReward(rewardId) {
    if (!firestore) {
        showSnackbar('Firestore not initialized', true);
        return;
    }
    
    try {
        const doc = await firestore.collection('Mobile App Rewards Data').doc(rewardId).get();
        if (!doc.exists) {
            showSnackbar('Reward not found', true);
            return;
        }
        
        const data = doc.data();
        editingRewardId = rewardId;
        document.getElementById('reward-form-title').textContent = 'Edit Reward';
        document.getElementById('reward-name').value = data.name || '';
        document.getElementById('reward-description').value = data.description || '';
        document.getElementById('reward-points').value = data.minimumRequirement || 0;
        document.getElementById('reward-code').value = data.redeemCode || '';
        document.getElementById('reward-platform').value = data.platform || 'both';
        document.getElementById('reward-form-modal').classList.add('show');
    } catch (error) {
        console.error('Error loading reward:', error);
        showSnackbar('Failed to load reward', true);
    }
}

async function deleteReward(rewardId, rewardName) {
    if (!confirm(`Are you sure you want to delete "${rewardName}"?`)) {
        return;
    }
    
    if (!firestore) {
        showSnackbar('Firestore not initialized', true);
        return;
    }
    
    try {
        await firestore.collection('Mobile App Rewards Data').doc(rewardId).delete();
        showSnackbar('Reward deleted successfully');
        loadRewards();
    } catch (error) {
        console.error('Error deleting reward:', error);
        showSnackbar('Failed to delete reward', true);
    }
}

document.getElementById('reward-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    if (!firestore) {
        showSnackbar('Firestore not initialized', true);
        return;
    }
    
    const name = document.getElementById('reward-name').value.trim();
    const description = document.getElementById('reward-description').value.trim();
    const points = parseInt(document.getElementById('reward-points').value);
    const code = document.getElementById('reward-code').value.trim().toUpperCase();
    const platform = document.getElementById('reward-platform').value;
    
    if (!name || !description || isNaN(points) || points < 0) {
        showSnackbar('Please fill in all required fields correctly', true);
        return;
    }
    
    try {
        const rewardData = {
            name: name,
            description: description,
            minimumRequirement: points,
            redeemCode: code || null,
            platform: platform,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
        };
        
        if (editingRewardId) {
            // Update existing reward
            await firestore.collection('Mobile App Rewards Data').doc(editingRewardId).update(rewardData);
            showSnackbar('Reward updated successfully');
        } else {
            // Create new reward
            rewardData.createdAt = firebase.firestore.FieldValue.serverTimestamp();
            await firestore.collection('Mobile App Rewards Data').add(rewardData);
            showSnackbar('Reward created successfully');
        }
        
        closeRewardFormModal();
        loadRewards();
    } catch (error) {
        console.error('Error saving reward:', error);
        showSnackbar('Failed to save reward', true);
    }
});

// Check if admin (you can implement your own admin check logic)
function checkAdminAccess() {
    // For now, always show admin button - you can add authentication later
    // You might want to check localStorage or a query parameter
    const urlParams = new URLSearchParams(window.location.search);
    const isAdmin = urlParams.get('admin') === 'true' || localStorage.getItem('kiosk_admin') === 'true';
    
    const adminBtn = document.getElementById('admin-reward-btn');
    if (adminBtn) {
        adminBtn.style.display = isAdmin ? 'block' : 'none';
    }
    
    return isAdmin;
}

// Trash Points Management Functions
function showTrashPointsScreen() {
    showScreen('trash-points');
    loadTrashPoints();
}

function showAdminRewards() {
    showScreen('admin-rewards');
    loadRewards();
}

async function loadTrashPoints() {
    if (!firestore) {
        console.warn('⚠️ Firestore not initialized - using default trash points');
        // Use default values from appState
        updateTrashPointsUI();
        return;
    }
    
    try {
        // Try to load from "Trash Points" collection (same as Flutter app)
        const docRef = firestore.collection('Trash Points').doc('points_config');
        const doc = await docRef.get();
        
        if (doc.exists) {
            const data = doc.data();
            appState.trashPoints = {
                plastic: parseFloat(data['Plastic'] || data.plastic || 5),
                paper: parseFloat(data['Paper'] || data.paper || 3),
                'single-stream': parseFloat(data['Single-stream'] || data['single-stream'] || data.singleStream || 4),
                mixed: parseFloat(data['Mixed'] || data.mixed || 1)
            };
            // Mark as configured if document exists
            appState.trashPointsConfigured = true;
            console.log('✅ Loaded trash points from Firestore (Trash Points collection):', appState.trashPoints);
        } else {
            // Fallback to "Kiosk Settings" collection for backward compatibility
            const fallbackDocRef = firestore.collection('Kiosk Settings').doc('trash_points');
            const fallbackDoc = await fallbackDocRef.get();
            
            if (fallbackDoc.exists) {
                const data = fallbackDoc.data();
                appState.trashPoints = {
                    plastic: parseFloat(data.plastic || 5),
                    paper: parseFloat(data.paper || 3),
                    'single-stream': parseFloat(data['single-stream'] || data.singleStream || 4),
                    mixed: parseFloat(data.mixed || 1)
                };
                // Mark as configured if document exists
                appState.trashPointsConfigured = true;
                console.log('✅ Loaded trash points from Firestore (Kiosk Settings collection):', appState.trashPoints);
            } else {
                console.log('ℹ️ No trash points found in Firestore, using defaults');
                // Not configured - admin hasn't set points yet
                appState.trashPointsConfigured = false;
            }
        }
        
        updateTrashPointsUI();
    } catch (error) {
        console.error('❌ Error loading trash points:', error);
        showSnackbar('Failed to load trash points', true);
        // Use default values
        updateTrashPointsUI();
    }
}

function updateTrashPointsUI() {
    document.getElementById('plastic-points').value = appState.trashPoints.plastic || 5.0;
    document.getElementById('paper-points').value = appState.trashPoints.paper || 3.0;
    document.getElementById('single-stream-points').value = appState.trashPoints['single-stream'] || 4.0;
}

async function saveTrashPoints() {
    const plasticPoints = parseFloat(document.getElementById('plastic-points').value) || 0;
    const paperPoints = parseFloat(document.getElementById('paper-points').value) || 0;
    const singleStreamPoints = parseFloat(document.getElementById('single-stream-points').value) || 0;
    
    if (plasticPoints < 0 || paperPoints < 0 || singleStreamPoints < 0) {
        showSnackbar('Points cannot be negative', true);
        return;
    }
    
    if (isNaN(plasticPoints) || isNaN(paperPoints) || isNaN(singleStreamPoints)) {
        showSnackbar('Please enter valid numbers', true);
        return;
    }
    
    // Update app state
    appState.trashPoints = {
        plastic: plasticPoints,
        paper: paperPoints,
        'single-stream': singleStreamPoints,
        mixed: 1.0 // Mixed always gives 1 point
    };
    
    if (!firestore) {
        console.warn('⚠️ Firestore not initialized - trash points saved to localStorage only');
        // Save to localStorage as backup
        localStorage.setItem('kiosk_trash_points', JSON.stringify(appState.trashPoints));
        showSnackbar('Trash points saved (local only)', true);
        return;
    }
    
    try {
        // Save to "Trash Points" collection (same as Flutter app)
        const docRef = firestore.collection('Trash Points').doc('points_config');
        await docRef.set({
            'Plastic': plasticPoints,
            'Paper': paperPoints,
            'Single-stream': singleStreamPoints,
            'Mixed': 1,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        
        // Also save to "Kiosk Settings" for backward compatibility
        const fallbackDocRef = firestore.collection('Kiosk Settings').doc('trash_points');
        await fallbackDocRef.set({
            plastic: plasticPoints,
            paper: paperPoints,
            'single-stream': singleStreamPoints,
            mixed: 1,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        
        console.log('✅ Trash points saved to Firestore');
        showSnackbar('Trash points saved successfully!');
        
        // Also save to localStorage as backup
        localStorage.setItem('kiosk_trash_points', JSON.stringify(appState.trashPoints));
        
        // Go back to admin rewards screen
        setTimeout(() => {
            showAdminRewards();
        }, 1000);
    } catch (error) {
        console.error('❌ Error saving trash points:', error);
        showSnackbar('Failed to save trash points', true);
        
        // Save to localStorage as backup
        localStorage.setItem('kiosk_trash_points', JSON.stringify(appState.trashPoints));
    }
}

// Calculate points for regular trash based on all items thrown
function calculateRegularTrashPoints(itemsThrown) {
    let totalPoints = 0;
    itemsThrown.forEach(type => {
        const pointsPerItem = appState.trashPoints[type] || 0;
        totalPoints += pointsPerItem;
    });
    return totalPoints;
}

// Generate a unique 4-digit code
async function generateUnique4DigitCode() {
    if (!firestore) {
        // If Firestore not available, just generate a random code
        return String(Math.floor(1000 + Math.random() * 9000));
    }
    
    let attempts = 0;
    const maxAttempts = 10;
    
    while (attempts < maxAttempts) {
        // Generate a random 4-digit number (1000-9999)
        const code = String(Math.floor(1000 + Math.random() * 9000));
        
        try {
            // Check if code already exists in "Codes from Regular Trash"
            const codesRef = firestore.collection('Codes from Regular Trash');
            const snapshot = await codesRef.where('code', '==', code).limit(1).get();
            
            if (snapshot.empty) {
                // Code is unique, return it
                return code;
            }
            
            // Code exists, try again
            attempts++;
        } catch (error) {
            console.warn('Error checking code uniqueness, using generated code:', error);
            // If check fails, return the code anyway
            return code;
        }
    }
    
    // If we couldn't find a unique code after max attempts, return a random one with timestamp
    // This is very unlikely but ensures we always return a code
    return String(Math.floor(1000 + Math.random() * 9000)) + String(Date.now()).slice(-1);
}

// Handle regular trash completion: calculate points, generate code, save to Firestore, and display
async function handleRegularTrashCompletion(feedback, itemsThrown, typeCounts) {
    // Check if trash points are configured
    if (!appState.trashPointsConfigured) {
        // Show notification that points and codes are not ready
        showPointsNotReadyModal();
        
        // Reset regular trash state
        appState.regularTrashCount = 0;
        appState.regularTrashType = null;
        appState.regularTrashItems = [];
        return;
    }
    
    // Calculate total points based on all trash types thrown
    const totalPoints = calculateRegularTrashPoints(itemsThrown);
    
    if (totalPoints <= 0) {
        console.warn('⚠️ No points calculated for regular trash');
        appState.regularTrashCount = 0;
        appState.regularTrashType = null;
        appState.regularTrashItems = [];
        setTimeout(() => {
            goHome();
        }, 500);
        return;
    }
    
    // Generate a unique 4-digit code
    const code = await generateUnique4DigitCode();
    
    // Save to "Codes from Regular Trash" collection in Firestore
    if (firestore) {
        try {
            const codesCollection = firestore.collection('Codes from Regular Trash');
            await codesCollection.add({
                code: code,
                totalPoints: totalPoints,
                trashItems: itemsThrown, // Array of all items thrown
                typeCounts: typeCounts, // Object with counts per type: { plastic: 2, paper: 1 }
                timestamp: firebase.firestore.Timestamp.fromDate(feedback.timestamp),
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                isRedeemed: false
            });
            console.log(`✅ Saved code ${code} to "Codes from Regular Trash" collection`);
            console.log(`   Total points: ${totalPoints}`);
            console.log(`   Trash items:`, itemsThrown);
            console.log(`   Type counts:`, typeCounts);
        } catch (error) {
            console.error('❌ Error saving code to Firestore:', error);
            showSnackbar('Failed to save code. Please try again.', true);
            // Still show the code to user even if save fails
        }
    } else {
        console.warn('⚠️ Firestore not initialized - code not saved');
    }
    
    // Display the code to user
    document.getElementById('reward-code-display').textContent = code;
    
    // Update modal text for regular trash
    const descElement = document.getElementById('reward-code-description');
    if (descElement) {
        descElement.textContent = `Congratulations! You earned ${totalPoints} points. Here is your 4-digit reward code:`;
    }
    
    // Show the code modal
    showModal('reward-code-modal');
    
    // Reset regular trash state
    appState.regularTrashCount = 0;
    appState.regularTrashType = null;
    appState.regularTrashItems = [];
}

// Save trash points earned to Firestore for tracking
async function saveTrashPointsEarned(type, count, points, timestamp) {
    if (!firestore) {
        console.warn('⚠️ Firestore not initialized - points earned not saved');
        return;
    }
    
    try {
        const pointsCollection = firestore.collection('Trash Points Earned');
        await pointsCollection.add({
            type: type,
            count: count,
            points: points,
            timestamp: firebase.firestore.Timestamp.fromDate(timestamp),
            createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
        console.log(`✅ Saved ${points} points earned for ${count} ${type} item(s)`);
    } catch (error) {
        console.error('❌ Error saving points earned:', error);
        // Don't show error to user, just log it
    }
}

// Set up real-time listener for trash points
function setupTrashPointsListener() {
    if (!firestore) {
        console.warn('Firestore not initialized - real-time trash points updates disabled');
        return;
    }
    
    try {
        // Listen to "Trash Points" collection (primary)
        const docRef = firestore.collection('Trash Points').doc('points_config');
        docRef.onSnapshot((doc) => {
            if (doc.exists) {
                const data = doc.data();
                appState.trashPoints = {
                    plastic: parseFloat(data['Plastic'] || data.plastic || 5),
                    paper: parseFloat(data['Paper'] || data.paper || 3),
                    'single-stream': parseFloat(data['Single-stream'] || data['single-stream'] || data.singleStream || 4),
                    mixed: parseFloat(data['Mixed'] || data.mixed || 1)
                };
                appState.trashPointsConfigured = true;
                console.log('✅ Trash points updated in real-time:', appState.trashPoints);
            } else {
                // If primary doesn't exist, check if fallback exists
                firestore.collection('Kiosk Settings').doc('trash_points').get().then((fallbackDoc) => {
                    if (!fallbackDoc.exists) {
                        appState.trashPointsConfigured = false;
                        console.log('ℹ️ Trash points not configured');
                    }
                });
            }
        }, (error) => {
            console.error('Error listening to trash points:', error);
        });
        
        // Also listen to fallback collection
        const fallbackDocRef = firestore.collection('Kiosk Settings').doc('trash_points');
        fallbackDocRef.onSnapshot((fallbackDoc) => {
            if (fallbackDoc.exists) {
                const data = fallbackDoc.data();
                appState.trashPoints = {
                    plastic: parseFloat(data.plastic || 5),
                    paper: parseFloat(data.paper || 3),
                    'single-stream': parseFloat(data['single-stream'] || data.singleStream || 4),
                    mixed: parseFloat(data.mixed || 1)
                };
                appState.trashPointsConfigured = true;
                console.log('✅ Trash points updated in real-time (Kiosk Settings):', appState.trashPoints);
            } else {
                // If fallback doesn't exist, check if primary exists
                firestore.collection('Trash Points').doc('points_config').get().then((primaryDoc) => {
                    if (!primaryDoc.exists) {
                        appState.trashPointsConfigured = false;
                        console.log('ℹ️ Trash points not configured');
                    }
                });
            }
        }, (error) => {
            console.error('Error listening to fallback trash points:', error);
        });
    } catch (error) {
        console.error('Error setting up trash points listener:', error);
    }
}

// Check if reward codes are available
async function checkCodeAvailability() {
    if (!firestore) {
        const statusDiv = document.getElementById('code-status');
        if (statusDiv) {
            statusDiv.innerHTML = '<p style="color: #f44336;">⚠️ Firestore not initialized</p>';
        }
        return false;
    }
    
    try {
        const codesRef = firestore.collection('Reward Codes');
        const snapshot = await codesRef
            .where('isRedeemed', '==', false)
            .where('isAssigned', '==', false)
            .limit(1)
            .get();
        
        const statusDiv = document.getElementById('code-status');
        if (statusDiv) {
            if (snapshot.empty) {
                statusDiv.innerHTML = '<p style="color: #f44336; font-weight: 600;">⚠️ No codes available. Admin will add more soon.</p>';
                return false;
            } else {
                statusDiv.innerHTML = '<p style="color: #4CAF50;">✓ Codes available</p>';
                return true;
            }
        }
        return !snapshot.empty;
    } catch (error) {
        console.error('Error checking code availability:', error);
        const statusDiv = document.getElementById('code-status');
        if (statusDiv) {
            statusDiv.innerHTML = '<p style="color: #f44336;">Error checking availability</p>';
        }
        return false;
    }
}

// Redeem code in kiosk
async function redeemCodeInKiosk() {
    const codeInput = document.getElementById('code-input');
    const code = codeInput?.value.trim();
    const statusDiv = document.getElementById('code-status');
    
    if (!code || code.length !== 4) {
        if (statusDiv) {
            statusDiv.innerHTML = '<p style="color: #f44336;">Please enter a 4-digit code</p>';
        }
        return;
    }
    
    // Check availability first
    const hasCodes = await checkCodeAvailability();
    if (!hasCodes) {
        showSnackbar('No codes available. Admin will add more soon.', true);
        return;
    }
    
    if (!firestore) {
        showSnackbar('Firestore not initialized', true);
        return;
    }
    
    try {
        // Find the code
        const codesRef = firestore.collection('Reward Codes');
        const snapshot = await codesRef
            .where('code', '==', code)
            .where('isRedeemed', '==', false)
            .limit(1)
            .get();
        
        if (snapshot.empty) {
            if (statusDiv) {
                statusDiv.innerHTML = '<p style="color: #f44336;">Invalid or already redeemed code</p>';
            }
            showSnackbar('Invalid or already redeemed code', true);
            return;
        }
        
        const doc = snapshot.docs[0];
        const data = doc.data();
        const points = data.points || 0;
        
        // Mark as redeemed (Note: In kiosk, we don't have user ID, so we'll mark it as redeemed without user info)
        await codesRef.doc(doc.id).update({
            isRedeemed: true,
            redeemedAt: firebase.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
        });
        
        if (statusDiv) {
            statusDiv.innerHTML = `<p style="color: #4CAF50; font-weight: 600;">✓ Code redeemed! You received ${points} points.</p>`;
        }
        showSnackbar(`Code redeemed successfully! You received ${points} points.`);
        codeInput.value = '';
        
        // Refresh availability check
        setTimeout(() => {
            checkCodeAvailability();
        }, 2000);
        
    } catch (error) {
        console.error('Error redeeming code:', error);
        if (statusDiv) {
            statusDiv.innerHTML = '<p style="color: #f44336;">Error redeeming code. Please try again.</p>';
        }
        showSnackbar('Error redeeming code', true);
    }
}

// Initialize on load
document.addEventListener('DOMContentLoaded', () => {
    init();
    checkAdminAccess();
});
