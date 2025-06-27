# frozen_string_literal: true

require 'msid/version'
require 'socket'
require 'digest'
require 'open3'

module Msid
  class Error < StandardError; end

  # Generates a unique machine fingerprint ID.
  #
  # The fingerprint is created by collecting various system identifiers,
  # combining them into a single string, and then hashing it with SHA-256.
  # This makes the ID highly unique to the machine it's generated on.
  class Generator
    # Gathers a collection of machine-specific identifiers.
    # @return [Array<String>] a list of identifiers.
    def self.gather_components
      [
        hostname,
        all_mac_addresses,
        cpu_info,
        cpu_cores,
        total_memory,
        os_info,
        serial_number,
        hardware_uuid,
        baseboard_serial,
        disk_uuid,
        system_model,
        gpu_info,
        bios_info,
        all_disk_serials
      ].compact.reject(&:empty?)
    end

    # Generates the unique machine ID.
    # @param salt [String, nil] An optional salt to add to the fingerprint.
    # @return [String] The SHA-256 hash representing the machine ID.
    def self.generate(salt: nil)
      components = gather_components
      raise Error, 'Could not gather any machine identifiers.' if components.empty?

      components.push(salt.to_s) if salt

      data_string = components.join(':')
      Digest::SHA256.hexdigest(data_string)
    end

    private

    # Executes a shell command and returns its stripped stdout.
    # Returns nil if the command fails or an error occurs.
    def self.run_command(command)
      stdout, _stderr, status = Open3.capture3(command)
      status.success? ? stdout.strip : nil
    rescue StandardError
      nil
    end

    # @return [String, nil] The machine's hostname.
    def self.hostname
      Socket.gethostname
    rescue StandardError
      nil
    end

    # @return [String, nil] A sorted, concatenated string of all MAC addresses.
    def self.all_mac_addresses
      macs = case RUBY_PLATFORM
             when /darwin/ # macOS
               run_command("ifconfig -a | grep -o -E '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}'")&.split("\n")
             when /linux/
               # Read from /sys/class/net, which is more reliable than parsing `ip` command output
               begin
                 Dir.glob('/sys/class/net/*/address').map { |f| File.read(f).strip }
               rescue StandardError
                 []
               end
             when /mswin|mingw/ # Windows
               run_command('getmac /v /fo csv | findstr /V "Disconnected"')
             &.lines
             &.map { |line| line.split(',')[2]&.gsub('"', '')&.strip }
             else
               []
             end
      macs&.compact&.reject(&:empty?)&.sort&.join(',')
    end

    # @return [String, nil] CPU model information.
    def self.cpu_info
      case RUBY_PLATFORM
      when /darwin/
        run_command('sysctl -n machdep.cpu.brand_string')
      when /linux/
        run_command("grep 'model name' /proc/cpuinfo | uniq | awk -F': ' '{print $2}'")
      when /mswin|mingw/
        run_command('wmic cpu get name /format:list | findstr "Name="')&.gsub('Name=', '')
      else
        nil
      end
    end

    # @return [String, nil] Number of CPU cores.
    def self.cpu_cores
      case RUBY_PLATFORM
      when /darwin/
        run_command('sysctl -n hw.ncpu')
      when /linux/
        run_command('nproc')
      when /mswin|mingw/
        run_command('wmic cpu get NumberOfCores | findstr /V "NumberOfCores"')
      else
        nil
      end
    end

    # @return [String, nil] Total physical memory in bytes or KB.
    def self.total_memory
      case RUBY_PLATFORM
      when /darwin/
        run_command('sysctl -n hw.memsize')
      when /linux/
        run_command("grep MemTotal /proc/meminfo | awk '{print $2}'")
      when /mswin|mingw/
        run_command('wmic ComputerSystem get TotalPhysicalMemory | findstr /V "TotalPhysicalMemory"')
      else
        nil
      end
    end

    # @return [String, nil] Operating system and kernel information.
    def self.os_info
      kernel_info = case RUBY_PLATFORM
                    when /mswin|mingw/
                      run_command('ver')
                    else
                      run_command('uname -r')
                    end
      "#{RUBY_PLATFORM}-#{kernel_info}"
    end

    # @return [String, nil] The machine's hardware serial number.
    def self.serial_number
      case RUBY_PLATFORM
      when /darwin/
        run_command("system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}'")
      when /linux/
        run_command('cat /sys/class/dmi/id/product_serial')
      when /mswin|mingw/
        run_command('wmic bios get serialnumber | findstr /V "SerialNumber"')
      else
        nil
      end
    end

    # @return [String, nil] The machine's hardware UUID.
    def self.hardware_uuid
      case RUBY_PLATFORM
      when /darwin/
        run_command("system_profiler SPHardwareDataType | awk '/Hardware UUID/ {print $3}'")
      when /linux/
        run_command('cat /sys/class/dmi/id/product_uuid')
      when /mswin|mingw/
        run_command('wmic csproduct get uuid | findstr /V "UUID"')
      else
        nil
      end
    end

    # @return [String, nil] The machine's baseboard serial number.
    def self.baseboard_serial
      case RUBY_PLATFORM
      when /darwin/
        nil # Not easily available/distinct from system serial on macOS
      when /linux/
        run_command('cat /sys/class/dmi/id/board_serial')
      when /mswin|mingw/
        run_command('wmic baseboard get serialnumber | findstr /V "SerialNumber"')
      else
        nil
      end
    end

    # @return [String, nil] The UUID of the root volume.
    def self.disk_uuid
      case RUBY_PLATFORM
      when /darwin/
        run_command("diskutil info / | awk '/Volume UUID/{print $3}'")
      when /linux/
        device = run_command("df / | tail -n1 | awk '{print $1}'")
        run_command("lsblk -no UUID #{device}") if device
      when /mswin|mingw/
        run_command('vol c: | findstr "Serial Number"')&.split&.last
      else
        nil
      end
    end

    # @return [String, nil] The machine's system model identifier.
    def self.system_model
      case RUBY_PLATFORM
      when /darwin/
        run_command("system_profiler SPHardwareDataType | awk '/Model Identifier/ {print $3}'")
      when /linux/
        run_command('cat /sys/class/dmi/id/product_name')
      when /mswin|mingw/
        run_command('wmic csproduct get name | findstr /V "Name"')
      else
        nil
      end
    end

    # @return [String, nil] The machine's GPU information.
    def self.gpu_info
      case RUBY_PLATFORM
      when /darwin/
        run_command("system_profiler SPDisplaysDataType | grep 'Chipset Model:' | awk -F': ' '{print $2}'")
      when /linux/
        run_command("lspci | grep -i 'vga\\|3d\\|2d' | head -n 1 | awk -F': ' '{print $3}'")
      when /mswin|mingw/
        run_command('wmic path win32_videocontroller get name | findstr /V "Name"')
      else
        nil
      end
    end

    # @return [String, nil] The machine's BIOS/firmware information.
    def self.bios_info
      case RUBY_PLATFORM
      when /darwin/
        run_command("system_profiler SPHardwareDataType | awk '/Boot ROM Version/ {print $4}'")
      when /linux/
        vendor = run_command('cat /sys/class/dmi/id/bios_vendor')
        version = run_command('cat /sys/class/dmi/id/bios_version')
        "#{vendor}-#{version}" if vendor && version
      when /mswin|mingw/
        run_command('wmic bios get manufacturer,version /format:list')
      else
        nil
      end
    end

    # @return [String, nil] A sorted, concatenated string of all physical disk serial numbers.
    def self.all_disk_serials
      serials = case RUBY_PLATFORM
                when /darwin/
                  run_command("system_profiler SPStorageDataType | grep 'Serial Number:' | awk '{print $3}'")&.split("\n")
                when /linux/
                  run_command('lsblk -d -o serial -n')&.split("\n")
                when /mswin|mingw/
                  run_command('wmic diskdrive get serialnumber | findstr /V "SerialNumber"')&.split("\n")
                else
                  []
                end
      serials&.compact&.map(&:strip)&.reject(&:empty?)&.sort&.join(',')
    end
  end

  # Shortcut for Msid::Generator.generate
  # @param salt [String, nil] An optional salt to add to the fingerprint.
  def self.generate(salt: nil)
    Generator.generate(salt: salt)
  end
end
