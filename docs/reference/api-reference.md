# YeelightControl API Reference

## Quick Links
- 📖 [Getting Started Guide](../guides/getting-started.md)
- 🔒 [Security Guide](../guides/security.md)
- ❓ [Troubleshooting](../guides/troubleshooting.md)
- 📝 [Examples](../examples/)

## Table of Contents
- [Overview](#overview)
- [Core APIs](#core-apis)
- [Feature APIs](#feature-apis)
- [UI Components](#ui-components)
- [Widget Integration](#widget-integration)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Testing](#testing)

## Overview

### API Layers
> 📘 For implementation details, see:
> - [Basic Control Example](../examples/basic-control/README.md)
> - [Effects Example](../examples/effects/README.md)
> - [UI Documentation](../Sources/UI/README.md)

### Common Patterns
> 📘 For detailed examples, see:
> - [Error Handling Example](../examples/error-handling/README.md)
> - [Best Practices Guide](../guides/best-practices.md)

## Core APIs

### Device Management
> 📘 Implementation: [Basic Device Control Example](../examples/basic-control/README.md)
> 
> 🔧 Troubleshooting: [Device Issues Guide](../guides/troubleshooting.md#device-issues)
>
> 📝 Reference: [Core Module Documentation](../../Sources/Core/README.md#key-components)

### Effect Management
> 📘 Implementation: [Lighting Effects Example](../examples/effects/README.md)
>
> ⚡ Performance: [Performance Guide](../guides/troubleshooting.md#performance)
>
> 📝 Reference: [Core Module Documentation](../../Sources/Core/README.md#key-components)

### Scene Management
> 📘 Implementation: [Scene Management Example](../examples/scenes/README.md)
>
> 🔄 Migration: [Scene Migration Guide](../guides/migration.md#scene-management)
>
> 📝 Reference: [Core Module Documentation](../../Sources/Core/README.md#key-components)

## Feature APIs

### Automation
> 📘 Implementation: [Automation Example](../examples/automation/README.md)
>
> 📝 Reference: [Features Module Documentation](../../Sources/Features/README.md#key-components)

### Room Management
> 📘 Implementation: [Room Management Example](../examples/rooms/README.md)
>
> 📝 Reference: [Features Module Documentation](../../Sources/Features/README.md#key-components)

## UI Components
> 📘 Implementation: [UI Examples](../examples/ui/README.md)
>
> 🎨 Design: [UI Guidelines](../guides/ui-guidelines.md)
>
> 📝 Reference: [UI Module Documentation](../../Sources/UI/README.md#key-components)

## Widget Integration
> 📘 Implementation: [Widget Example](../examples/widget/README.md)
>
> 📱 Setup: [Widget Setup Guide](../guides/widget-setup.md)
>
> 📝 Reference: [Widget Module Documentation](../../Sources/Widget/README.md#key-components)

## Error Handling
> 📘 Implementation: [Error Handling Example](../examples/error-handling/README.md)
>
> 🔧 Guide: [Troubleshooting Guide](../guides/troubleshooting.md)
>
> 📝 Reference: [Core Module Documentation](../../Sources/Core/README.md#error-handling)

## Best Practices

### Device Control
> 📘 Related: [Basic Device Control Example](../examples/basic-control/README.md)
>
> 🔧 See also: [Troubleshooting Device Issues](../guides/troubleshooting.md#device-issues)

- Always check device availability before sending commands
- Handle connection timeouts gracefully
- Implement automatic reconnection logic
- Cache device states for quick access
- Batch similar commands when possible
- Validate commands before sending

### Effect Management
> 📘 Related: [Lighting Effects Example](../examples/effects/README.md)
>
> ⚡ See also: [Performance Optimization](../guides/troubleshooting.md#performance)

- Validate effect parameters before creation
- Check device compatibility
- Implement proper timing control
- Cache commonly used effects
- Handle effect interruptions
- Monitor effect execution

### Scene Management
> 📘 Related: [Scene Management Example](../examples/scenes/README.md)
>
> 🔄 See also: [Scene Migration](../guides/migration.md#scene-management)

- Validate device configurations
- Implement proper naming conventions
- Handle scheduling requirements
- Check device availability
- Implement fallback options
- Monitor activation status

### Error Handling
> 📘 Related: [Error Handling Example](../examples/error-handling/README.md)
>
> 🔧 See also: [Troubleshooting Guide](../guides/troubleshooting.md)

- Implement proper error categorization
- Provide detailed error context
- Handle nested errors
- Log error occurrences
- Implement automatic recovery where possible
- Monitor error patterns

## Testing
> 📘 Implementation: [Testing Example](../examples/testing/README.md)
>
> 🔧 Guide: [Testing Guide](../guides/testing.md)
>
> 📝 Reference: [Test Utilities Documentation](../Sources/Tests/README.md)

## Additional Resources
- [Getting Started Guide](../guides/getting-started.md)
- [Migration Guide](../guides/migration.md)
- [Security Guide](../guides/security.md)
- [Troubleshooting Guide](../guides/troubleshooting.md)
- [Examples](../examples/) 