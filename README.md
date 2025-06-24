# LC Phone
An advanced standalone phone system for FiveM servers with a modern interface and extensive features.

## Dependencies
- ox_lib
- oxmysql (for database handling)

## Screenshots
- Coming soon

## Features
- **Completely standalone** - works without any specific framework
- Clean and modern UI inspired by modern smartphones
- Contact management system
- Messaging system with chat history
- Call system with call history
- Phone animation with proper prop attachment
- Customizable wallpapers and themes
- Notification system
- Settings to customize your experience
- Twitter-like social media app
- Bank app with transfer capabilities
- Gallery app for viewing and sharing photos

## Installation
1. Make sure you have the required dependencies installed
2. Import the `lc_phone.sql` file into your database
3. Add `ensure lc_phone` to your server.cfg
4. Configure the phone settings in `config.lua` to match your server's needs

## Usage
- Press `K` (default) to open the phone
- Navigate through apps by clicking on their icons
- Use the home button at the bottom to return to the home screen

## Development
This phone system is built with:
- Lua for server and client scripts
- HTML/CSS/JS for the user interface
- Using NUI callbacks for communication between Lua and JS

## Configuration
You can configure various aspects of the phone in the `config.lua` file:
- Phone key binding
- Phone model
- Call volume
- Available apps
- Phone number format
- Animation settings
- Identifier type (license, steam, discord)
- Option to make the phone an item

## Credits
- Developed by LC Development
- Based on ideas from qb-phone but completely standalone
