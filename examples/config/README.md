# Configuration Templates

This directory contains **template configuration files** for reference and documentation purposes.

## Files

- **logging.properties** - Template for RELEASE mode configuration
- **logging-debug.properties** - Template for DEBUG mode configuration

## Important Notes

⚠️ **These files are NOT used directly by the examples.**

Each example that requires configuration has its own local copy of these files in its directory. This ensures:

- **Independence**: Each example is self-contained and can run from any location
- **Clean Architecture**: No coupling between examples through shared configuration
- **Flexibility**: Examples can be customized without affecting others

## Usage

### For New Examples

If you're creating a new example that needs configuration:

1. Copy `logging.properties` and/or `logging-debug.properties` to your example's directory
2. Customize the configuration as needed for your example
3. The LoggingFacade framework will automatically discover the config file in the executable's directory

### Configuration Discovery

The framework searches for configuration files in this order:

1. Current working directory
2. Executable directory
3. Parent directory

For DEBUG builds: `logging-debug.properties`
For RELEASE builds: `logging.properties`

## Examples with Local Configuration

Examples that include their own configuration files:

- **BasicExample** - Demonstrates automatic configuration loading
- **ConfigExample** - Demonstrates all configuration features
- **HierarchicalDemo** - Shows hierarchical logger configuration
- **AutoReloadExample** - Demonstrates automatic config reloading

## See Also

- [Main README](../../README.md) - Complete framework documentation
- [ConfigExample](../ConfigExample/) - Comprehensive configuration demonstration
- [Logger.Config.pas](../../src/Logger.Config.pas) - Configuration implementation
