# Hyprland Configuration

A comprehensive, modern, rust-powered Hyprland 🍚 with a focus on featuring automated theme management, dynamic wallpaper integration, and seamless workflow optimization.
## Overview

This configuration provides a complete desktop environment built around Hyprland with intelligent automation systems. The setup includes dynamic theme synchronization across all applications, animated wallpaper support, and a modular script architecture for system management.

## Key Features

### Automated Theme Management

- **Dynamic Color Extraction**: Automatically generates color schemes from wallpapers using Wallust
- **System-wide Synchronization**: Updates GTK themes, terminal colors, Waybar, and application themes
- **GIF Wallpaper Support**: Seamless integration with animated wallpapers via waytrogen and swww
- **Intelligent Adaptation**: Adjusts interface elements based on wallpaper luminosity

### Modular Script Architecture

- **Theme Orchestration**: Centralized theme management with component-specific handlers
- **Media Controls**: Unified volume, brightness, and playback management with visual feedback
- **System Utilities**: Package update monitoring, git repository maintenance, and status displays
- **Error Handling**: Comprehensive logging, notifications, and recovery mechanisms

### Application Integration

- **Terminal**: Alacritty, Kitty with dynamic color schemes
- **Shell**: Zsh and Bash with unified environment configuration
- **Editor**: Neovim with theme synchronization
- **Browser**: Custom themes and integration
- **Development**: VSCode, various development tools

## Configuration Structure

```
~/.config/
├── hypr/           # Hyprland configuration
├── waybar/         # Status bar configuration
├── scripts/        # Automation and utility scripts
├── wallust/        # Color palette templates
├── themes/         # GTK and application themes
└── [applications]/ # Individual application configs
```

## Script System

The configuration includes a modular script system organized by functionality:

- **Theme Management**: Automated theme synchronization and wallpaper processing
- **Media Controls**: Volume, brightness, and playback management
- **System Utilities**: Package updates, git maintenance, status monitoring
- **Development Tools**: Project management and workflow automation

For detailed script documentation, see [`scripts/README.md`](scripts/README.md).

## Customization

### Theme Modification

- Edit Wallust templates in `wallust/templates/`
- Modify color mappings in theme scripts
- Adjust application-specific configurations

### Script Configuration

- Update script constants for personal preferences
- Modify notification settings and thresholds
- Customize automation triggers and behaviors

### Application Integration

- Configure individual applications in their respective directories
- Update environment variables in `shell.env`
- Modify keybindings in Hyprland configuration

## Contributing

Contributions are welcome and appreciated. Please follow these guidelines:

1. **Issues**: Report bugs or request features via GitHub issues
2. **Pull Requests**: Ensure code follows existing patterns and includes documentation
3. **Testing**: Test changes across different scenarios and configurations
4. **Documentation**: Update relevant documentation for any changes

## License

This configuration is provided as-is for educational and personal use. Individual components may have their own licenses.

---

**Author**: saatvik333
**Support**: Star the repository if you find it useful
