# App Module

## Overview
The App module serves as the entry point for the YeelightControl application, coordinating between modules and managing the application lifecycle.

> 📘 For detailed documentation, see:
> - [Getting Started Guide](../../docs/guides/getting-started.md)
> - [Architecture Overview](../../docs/reference/api-reference.md#overview)
> - [Best Practices](../../docs/reference/api-reference.md#best-practices)

## Directory Structure
```
App/
├── YeelightControlApp.swift - Application entry point
├── ContentView.swift        - Root view
├── AppDelegate.swift       - App lifecycle management
├── Coordinators/           - Module coordination
├── DependencyInjection/    - Service registration
└── Configuration/          - App configuration
```

## Key Components

### Application Entry
> 📘 [App Configuration](../../docs/guides/getting-started.md#configuration)
>
> 📝 [Example Setup](../../docs/examples/basic-control/README.md#setup)

### Module Coordination
> 📘 [Architecture Overview](../../docs/reference/api-reference.md#overview)
>
> 📝 [Integration Guide](../../docs/guides/getting-started.md#integration)

## Dependencies
- Core Module
- Features Module
- UI Module
- Widget Module

> 🔧 For troubleshooting, see the [Troubleshooting Guide](../../docs/guides/troubleshooting.md)
>
> 📱 For UI integration, see the [UI Guidelines](../../docs/guides/ui-guidelines.md)
