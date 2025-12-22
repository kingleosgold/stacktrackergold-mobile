# Contributing to Stack Tracker Pro

First off, thank you for considering contributing to Stack Tracker Pro! 🪙

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

**When reporting a bug, include:**
- Device and OS version
- App version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable

**Important:** Never include your actual portfolio data or receipt images in bug reports!

### Suggesting Features

We love feature suggestions! Please open an issue with:
- Clear description of the feature
- Why it would be useful for stackers
- Any privacy implications to consider

### Pull Requests

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Ensure no sensitive data is included
5. Test thoroughly
6. Commit with clear messages (`git commit -m 'Add amazing feature'`)
7. Push to your branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## Development Setup

### Prerequisites
- Node.js 18+
- Expo CLI
- Anthropic API key (for receipt scanning backend)

### Local Development

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/stack-tracker-pro.git
cd stack-tracker-pro

# Install mobile app dependencies
cd mobile-app
npm install

# Start the app
npx expo start

# In another terminal, start the backend
cd ../backend
npm install
ANTHROPIC_API_KEY=your-key npm start
```

## Privacy Guidelines

**This is critical:** Stack Tracker Pro is a privacy-first application. Any contributions must maintain our privacy standards:

### DO:
- Keep all user data processing local to device
- Use memory-only processing for images
- Minimize data transmission
- Document any data handling clearly

### DON'T:
- Add analytics or tracking SDKs
- Log user data anywhere
- Store images or sensitive data on servers
- Add features that require user accounts

## Code Style

- Use clear, descriptive variable names
- Comment complex logic
- Follow existing code patterns
- Keep functions focused and small

## Questions?

Feel free to open an issue with your question or reach out to the maintainers.

Thank you for helping make Stack Tracker Pro better! 🥈🥇
