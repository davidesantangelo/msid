# msid

`msid` is a Ruby gem for generating a unique and secure machine fingerprint ID. It gathers a wide range of system identifiers to create a hash that is highly specific to the machine it's run on.

This is useful for licensing, device identification, or any scenario where you need to reliably identify a specific machine.

## How It Works

`msid` collects the following system information:
- Hostname
- All MAC addresses
- CPU model and core count
- Total RAM
- OS and kernel information
- Hardware Serial Number
- Hardware UUID
- Motherboard Serial Number
- Root disk volume UUID
- System Model Identifier
- GPU Information
- BIOS/Firmware Information
- Serial numbers of all physical disks

It then combines these components into a single string and uses the SHA-256 algorithm to produce a consistent, unique fingerprint.

## Use Cases

Here are some practical scenarios where `msid` can be valuable:

### Software Licensing
- **Offline License Activation**: Bind software licenses to specific machines without requiring constant internet validation.
- **Trial Period Management**: Track installations to prevent users from repeatedly installing trial versions.
- **License Auditing**: Keep track of which machines have your software installed for compliance purposes.

### Security Applications
- **Multi-factor Authentication**: Add an extra layer of security by validating not just "something you know" (password) but also "something you have" (the specific device).
- **Session Security**: Detect when a user's session moves to a different machine, potentially indicating session hijacking.
- **Fraud Detection**: Flag accounts that suddenly access your service from multiple different machines in rapid succession.

### System Management
- **Asset Tracking**: Inventory management for IT departments to track hardware across an organization.
- **Configuration Management**: Associate specific configurations or settings with particular machines.
- **Environment-specific Features**: Enable or disable features based on the hardware environment.

### DevOps and Deployment
- **Environment Fingerprinting**: Distinguish between development, staging, and production environments.
- **Deployment Validation**: Ensure that deployments only happen from authorized build machines.
- **Infrastructure Auditing**: Track which servers or virtual machines are running your applications.

### Usage Analytics
- **Device Demographics**: Gather anonymous statistics about what kinds of machines are running your software.
- **Installation Metrics**: Track unique installations versus reinstallations.
- **Hardware Compatibility**: Identify hardware configurations where your software performs well or poorly.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'msid'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install msid

## Usage

### From Ruby

You can generate the machine ID from your Ruby code.

```ruby
require 'msid'

# Generate the default ID
machine_id = Msid.generate
puts machine_id
# => "a1b2c3d4..."
```

#### Using a Salt

For enhanced security, you can provide a `salt`. This is useful if you want to generate different IDs for different applications on the same machine.

```ruby
require 'msid'

# Generate an ID with a salt
app_specific_id = Msid.generate(salt: 'my-super-secret-app-key')
puts app_specific_id
# => "e5f6g7h8..." (different from the one without a salt)
```

### With IRB (for local development)

If you are developing the gem locally, you can test it with `irb`. From the root directory of the gem, run `irb` with the `-I` flag to add the `lib` directory to Ruby's load path.

```sh
$ irb -I lib
```

Then, inside `irb`, you can require and use the gem:

```ruby
irb(main):001:0> require 'msid'
=> true
irb(main):002:0> Msid.generate
=> "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2"
```

### In a Rails Application

To use `msid` in a Rails application, add it to your `Gemfile`.

If you are developing the gem locally, you can use the `path` option:
```ruby
# Gemfile
gem 'msid', path: '/path/to/your/msid/gem'
```

If the gem is on RubyGems, add it normally:
```ruby
# Gemfile
gem 'msid'
```

Then run `bundle install`.

Now you can use it anywhere in your Rails application, including the Rails console:

```sh
$ rails console
```

```ruby
# In Rails console
irb(main):001:0> Msid.generate
=> "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2"

# For extra security, you can use a Rails secret as a salt
irb(main):002:0> Msid.generate(salt: Rails.application.credentials.secret_key_base)
=> "f1e2d3c4b5a6f7e8d9c0b1a2f3e4d5c6b7a8f9e0d1c2b3a4f5e6d7c8b9a0f1e2"
```

### From the Command Line

The gem provides a command-line executable to easily retrieve the machine ID.

```sh
$ msid
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake test` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davidesantangelo/msid.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
