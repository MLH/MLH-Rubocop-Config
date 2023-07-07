# MLH Rubocop Configuration

The MLH Rubocop Configuration provides a set of rules and guidelines for Ruby code.

## Usage

To use the MLH Rubocop Configuration in your Ruby project, follow these steps:

1. Add the MLH Rubocop Configuration gem to your Gemfile:
   ```ruby
   gem "mlh-rubocop-config", git: "https://github.com/MLH/MLH-Rubocop-Config.git"
   ```

2. In your project's `.rubocop.yml` file, include the MLH Rubocop Configuration by using the inherit_gem directive:

```
inherit_gem:
  mlh-rubocop-config: .rubocop.yml
```

## Example

Here's an example of how your project's `.rubocop.yml` file might look like when using the MLH Rubocop Configuration:

```
# Inherit rules from the MLH Rubocop Configuration
inherit_gem:
  mlh-rubocop-config: .rubocop.yml

# Add project-specific rules or overrides
AllCops:
  Exclude:
    - spec/**/* # Exclude spec files from Rubocop analysis
```
