// Phone data
let phoneData = {
    number: '',
    contacts: [],
    messages: [],
    calls: [],
    notifications: []
};

// Current app state
let currentApp = 'home';
let currentChat = null;

// Initialize the phone
$(document).ready(function() {
    // Set up clock
    updateClock();
    setInterval(updateClock, 1000);
    
    // Populate apps from config
    populateApps();
    
    // Set up event listeners
    setupEventListeners();
    
    // NUI message handler
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.action === 'openPhone') {
            console.log("Opening phone UI");
            $('#phone-container').removeClass('hidden');
        } else if (data.action === 'closePhone') {
            console.log("Closing phone UI");
            $('#phone-container').addClass('hidden');
        } else if (data.action === 'updatePhoneData') {
            phoneData = data.data;
            updateApps();
        } else if (data.action === 'contactAdded') {
            phoneData.contacts.push(data.contact);
            if (currentApp === 'contacts') {
                renderContacts();
            }
        } else if (data.action === 'messageSent') {
            handleNewMessage(data.number, data.message);
        } else if (data.action === 'messageReceived') {
            handleNewMessage(data.number, data.message);
            // Play notification sound if needed
        }
    });
});

// Update clock
function updateClock() {
    const now = new Date();
    let hours = now.getHours();
    let minutes = now.getMinutes();
    
    // Format minutes to always have two digits
    minutes = minutes < 10 ? '0' + minutes : minutes;
    
    $('#phone-time').text(`${hours}:${minutes}`);
}

// Populate apps from config
function populateApps() {
    // This would ideally come from the config, but for now we'll hardcode
    const apps = [
        { id: 'phone', name: 'Phone', icon: 'phone', color: '#27ae60' },
        { id: 'messages', name: 'Messages', icon: 'comment', color: '#2ecc71' },
        { id: 'contacts', name: 'Contacts', icon: 'user', color: '#3498db' },
        { id: 'settings', name: 'Settings', icon: 'cog', color: '#636e72' }
    ];
    
    const appGrid = $('.app-grid');
    appGrid.empty();
    
    apps.forEach(app => {
        const appIcon = $(`
            <div class="app-icon" data-app="${app.id}">
                <div class="app-icon-img" style="background-color: ${app.color}">
                    <i class="fas fa-${app.icon}"></i>
                </div>
                <div class="app-name">${app.name}</div>
            </div>
        `);
        
        appGrid.append(appIcon);
    });
}

// Set up event listeners
function setupEventListeners() {
    // Home button
    $('#home-button').on('click', function() {
        navigateToApp('home');
    });
    
    // App icons
    $(document).on('click', '.app-icon', function() {
        const app = $(this).data('app');
        navigateToApp(app);
    });
    
    // Back buttons
    $(document).on('click', '.back-button', function() {
        navigateToApp('home');
    });
    
    // Dial pad buttons
    $(document).on('click', '.dial-button', function() {
        const digit = $(this).text();
        const currentNumber = $('#phone-number').val();
        $('#phone-number').val(currentNumber + digit);
    });
    
    // Call button
    $('#call-button').on('click', function() {
        const number = $('#phone-number').val();
        if (number.length > 0) {
            $.post('https://lc_phone/callNumber', JSON.stringify({
                number: number
            }));
        }
    });
    
    // New contact button
    $('#new-contact').on('click', function() {
        showNewContactForm();
    });
    
    // New message button
    $('#new-message').on('click', function() {
        showNewMessageForm();
    });
    
    // Contact item click
    $(document).on('click', '.contact-item', function() {
        const contactIndex = $(this).data('index');
        showContactDetails(phoneData.contacts[contactIndex]);
    });
    
    // Message item click
    $(document).on('click', '.message-item', function() {
        const number = $(this).data('number');
        openChatScreen(number);
    });
    
    // Send message button in chat
    $(document).on('click', '.send-message-btn', function() {
        const messageText = $('#message-input').val().trim();
        if (messageText.length > 0 && currentChat) {
            $.post('https://lc_phone/sendMessage', JSON.stringify({
                number: currentChat,
                message: messageText
            }));
            $('#message-input').val('');
        }
    });
    
    // Close phone with ESC key
    $(document).keyup(function(e) {
        if (e.key === "Escape") {
            $.post('https://lc_phone/closePhone', JSON.stringify({}));
        }
    });
}

// Navigate to app
function navigateToApp(app) {
    $('.screen').removeClass('active');
    
    if (app === 'home') {
        $('#home-screen').addClass('active');
    } else {
        $(`#${app}-app`).addClass('active');
        
        // Update app content
        if (app === 'contacts') {
            renderContacts();
        } else if (app === 'messages') {
            renderMessages();
        } else if (app === 'phone') {
            // Clear phone number input
            $('#phone-number').val('');
        }
    }
    
    currentApp = app;
    
    // Send NUI callback
    $.post('https://lc_phone/openApp', JSON.stringify({
        app: app
    }));
}

// Render contacts
function renderContacts() {
    const contactsList = $('.contacts-list');
    contactsList.empty();
    
    if (phoneData.contacts.length === 0) {
        contactsList.html('<div class="empty-state">No contacts</div>');
        return;
    }
    
    phoneData.contacts.forEach((contact, index) => {
        const contactItem = $(`
            <div class="contact-item" data-index="${index}">
                <div class="contact-name">${contact.name}</div>
                <div class="contact-actions">
                    <div class="contact-action call" data-number="${contact.number}">
                        <i class="fas fa-phone"></i>
                    </div>
                    <div class="contact-action message" data-number="${contact.number}">
                        <i class="fas fa-comment"></i>
                    </div>
                </div>
            </div>
        `);
        
        contactsList.append(contactItem);
    });
}

// Render messages
function renderMessages() {
    const messagesList = $('.messages-list');
    messagesList.empty();
    
    if (phoneData.messages.length === 0) {
        messagesList.html('<div class="empty-state">No messages</div>');
        return;
    }
    
    phoneData.messages.forEach(chat => {
        // Find contact name if available
        let contactName = chat.number;
        phoneData.contacts.forEach(contact => {
            if (contact.number === chat.number) {
                contactName = contact.name;
            }
        });
        
        // Get the last message
        const lastMessage = chat.messages[chat.messages.length - 1];
        
        const messageItem = $(`
            <div class="message-item" data-number="${chat.number}">
                <div class="message-info">
                    <div class="message-name">${contactName}</div>
                    <div class="message-preview">${lastMessage.message}</div>
                </div>
                <div class="message-time">${lastMessage.time}</div>
            </div>
        `);
        
        messagesList.append(messageItem);
    });
}

// Show new contact form
function showNewContactForm() {
    // Create a form overlay
    const formOverlay = $(`
        <div class="form-overlay">
            <div class="form-container">
                <h3>New Contact</h3>
                <div class="form-group">
                    <label>Name</label>
                    <input type="text" id="contact-name" placeholder="Enter name">
                </div>
                <div class="form-group">
                    <label>Number</label>
                    <input type="text" id="contact-number" placeholder="Enter number">
                </div>
                <div class="form-actions">
                    <button id="cancel-contact">Cancel</button>
                    <button id="save-contact">Save</button>
                </div>
            </div>
        </div>
    `);
    
    $('body').append(formOverlay);
    
    // Handle cancel
    $('#cancel-contact').on('click', function() {
        $('.form-overlay').remove();
    });
    
    // Handle save
    $('#save-contact').on('click', function() {
        const name = $('#contact-name').val().trim();
        const number = $('#contact-number').val().trim();
        
        if (name.length > 0 && number.length > 0) {
            $.post('https://lc_phone/addContact', JSON.stringify({
                name: name,
                number: number
            }));
            $('.form-overlay').remove();
        }
    });
}

// Show new message form
function showNewMessageForm() {
    // Create a form overlay
    const formOverlay = $(`
        <div class="form-overlay">
            <div class="form-container">
                <h3>New Message</h3>
                <div class="form-group">
                    <label>To</label>
                    <input type="text" id="message-recipient" placeholder="Enter number">
                </div>
                <div class="form-group">
                    <label>Message</label>
                    <textarea id="message-content" placeholder="Type your message"></textarea>
                </div>
                <div class="form-actions">
                    <button id="cancel-message">Cancel</button>
                    <button id="send-message">Send</button>
                </div>
            </div>
        </div>
    `);
    
    $('body').append(formOverlay);
    
    // Handle cancel
    $('#cancel-message').on('click', function() {
        $('.form-overlay').remove();
    });
    
    // Handle send
    $('#send-message').on('click', function() {
        const number = $('#message-recipient').val().trim();
        const message = $('#message-content').val().trim();
        
        if (number.length > 0 && message.length > 0) {
            $.post('https://lc_phone/sendMessage', JSON.stringify({
                number: number,
                message: message
            }));
            $('.form-overlay').remove();
        }
    });
}

// Show contact details
function showContactDetails(contact) {
    // Create a details overlay
    const detailsOverlay = $(`
        <div class="details-overlay">
            <div class="details-container">
                <h3>${contact.name}</h3>
                <div class="contact-detail">
                    <span>Number:</span>
                    <span>${contact.number}</span>
                </div>
                ${contact.iban ? `
                <div class="contact-detail">
                    <span>IBAN:</span>
                    <span>${contact.iban}</span>
                </div>
                ` : ''}
                <div class="contact-actions">
                    <button id="call-contact" data-number="${contact.number}">
                        <i class="fas fa-phone"></i> Call
                    </button>
                    <button id="message-contact" data-number="${contact.number}">
                        <i class="fas fa-comment"></i> Message
                    </button>
                </div>
                <div class="details-footer">
                    <button id="close-details">Close</button>
                </div>
            </div>
        </div>
    `);
    
    $('body').append(detailsOverlay);
    
    // Handle close
    $('#close-details').on('click', function() {
        $('.details-overlay').remove();
    });
    
    // Handle call
    $('#call-contact').on('click', function() {
        const number = $(this).data('number');
        $.post('https://lc_phone/callNumber', JSON.stringify({
            number: number
        }));
        $('.details-overlay').remove();
    });
    
    // Handle message
    $('#message-contact').on('click', function() {
        const number = $(this).data('number');
        $('.details-overlay').remove();
        openChatScreen(number);
    });
}

// Open chat screen
function openChatScreen(number) {
    // Find chat in phone data
    let chat = null;
    for (let i = 0; i < phoneData.messages.length; i++) {
        if (phoneData.messages[i].number === number) {
            chat = phoneData.messages[i];
            break;
        }
    }
    
    // If no chat exists, create one
    if (!chat) {
        chat = {
            number: number,
            messages: []
        };
        phoneData.messages.push(chat);
    }
    
    // Find contact name if available
    let contactName = number;
    phoneData.contacts.forEach(contact => {
        if (contact.number === number) {
            contactName = contact.name;
        }
    });
    
    // Create chat screen
    const chatScreen = $(`
        <div id="chat-screen" class="screen active">
            <div class="chat-header">
                <div class="chat-back">
                    <i class="fas fa-arrow-left"></i>
                </div>
                <div class="chat-title">${contactName}</div>
            </div>
            <div class="chat-messages">
                ${chat.messages.length === 0 ? 
                    '<div class="empty-state">No messages yet</div>' : 
                    renderChatMessages(chat.messages)}
            </div>
            <div class="chat-input">
                <input type="text" id="message-input" placeholder="Type a message">
                <button class="send-message-btn">
                    <i class="fas fa-paper-plane"></i>
                </button>
            </div>
        </div>
    `);
    
    // Hide other screens and show chat
    $('.screen').removeClass('active');
    $('#phone-screen').append(chatScreen);
    
    // Set current chat
    currentChat = number;
    
    // Handle back button
    $('.chat-back').on('click', function() {
        $('#chat-screen').remove();
        navigateToApp('messages');
    });
    
    // Scroll to bottom of chat
    setTimeout(() => {
        $('.chat-messages').scrollTop($('.chat-messages')[0].scrollHeight);
    }, 100);
}

// Render chat messages
function renderChatMessages(messages) {
    let html = '';
    
    messages.forEach(msg => {
        const isSender = msg.sender === phoneData.number;
        html += `
            <div class="chat-message ${isSender ? 'message-sent' : 'message-received'}">
                <div class="message-content">${msg.message}</div>
                <div class="message-time">${msg.time}</div>
            </div>
        `;
    });
    
    return html;
}

// Handle new message
function handleNewMessage(number, messageData) {
    // Find or create chat
    let chatIndex = -1;
    for (let i = 0; i < phoneData.messages.length; i++) {
        if (phoneData.messages[i].number === number) {
            chatIndex = i;
            break;
        }
    }
    
    if (chatIndex === -1) {
        phoneData.messages.push({
            number: number,
            messages: [messageData]
        });
    } else {
        phoneData.messages[chatIndex].messages.push(messageData);
    }
    
    // Update UI if needed
    if (currentApp === 'messages' && !currentChat) {
        renderMessages();
    } else if (currentChat === number) {
        // Add message to chat screen
        const isSender = messageData.sender === phoneData.number;
        const messageElement = $(`
            <div class="chat-message ${isSender ? 'message-sent' : 'message-received'}">
                <div class="message-content">${messageData.message}</div>
                <div class="message-time">${messageData.time}</div>
            </div>
        `);
        
        $('.chat-messages').append(messageElement);
        $('.chat-messages').scrollTop($('.chat-messages')[0].scrollHeight);
    }
}

// Update apps based on phone data
function updateApps() {
    if (currentApp === 'contacts') {
        renderContacts();
    } else if (currentApp === 'messages') {
        renderMessages();
    }
}

// Add a debug function to help with troubleshooting
function debug(message) {
    console.log('[LC Phone] ' + message);
    
    // Also send debug info to server
    $.post('https://lc_phone/debug', JSON.stringify({
        message: message
    }));
}

// Make sure to call this when the DOM is ready
$(document).ready(function() {
    debug('Phone UI Loaded - Waiting for open command');
});
