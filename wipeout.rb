#!/usr/bin/ruby
#
# Wipeout - Fast, secure, interactive disk erase utility
#
# Latest version here: https://github.com/courtney-rosenthal/wipeout
#

# Pattern that will match the device once it's connected to the system.
PATTERN_DEV = "/dev/sd?"

# After the wipe is performed, check this amount at the beginning of the
# disk to ensure it's all zeroes, to confirm a successful wipe.
WIPE_CHECK_MB = 500


#
# main - main program
#
def main
  if `id -u`.rstrip != "0"
    raise "This must be run as the root user."
  end

  dev = acquireDevice
  puts "Detected device = #{dev}"
  verifySecureWipeCapable(dev)
  confirmForWipe(dev)
  performWipe(dev)
  verifyWipe(dev)
end


#
# acquireDevice - wait for a device to be inserted
#
# Returns path of the device that was inserted
#
def acquireDevice
  devicesBefore = Dir.glob(PATTERN_DEV)
  print "Insert drive now .."
  loop do
    print "."
    sleep 1
    devicesAdded = Dir.glob(PATTERN_DEV) - devicesBefore
    case devicesAdded.length
    when 0
      # nothing added yet
    when 1
      puts " done!"
      return devicesAdded.first
    else
      raise "I'm confused -- I see multiple devices added!"
    end
  end
end


#
# getHdParamInfo - get info from a device with the "hdparam" command
#
# Returns a list of lines output by the command, with spaces collapsed and trimmed.
# Throws an exception of command fails.
#
def getHdParamInfo(dev)
  output = `hdparm -I #{dev}`
  if $?.exitstatus != 0
    raise "Failed to run hdparm."
  end

  lines = output.split("\n") \
    .map { |s| s.gsub(/[ \t]+/, " ") } \
    .map { |s| s.strip }

  if lines.empty?
    raise "Failed to retrieve output from hdparm command."
  end

  return lines
end


#
# verifySecureWipeCapable - verify device supports ATA Secure Erase
#
# Also displays some device information.
#
def verifySecureWipeCapable(dev)

  lines = getHdParamInfo(dev)
  if lines.include?("frozen")
    raise "Cannot wipe: device has been frozen."
  end
  if ! lines.include?("not frozen")
    raise "Cannot wipe: cannot verify device frozen state."
  end

  def lines.getLineFromList(re)
    result = self.filter { |s| s =~ re }
    if result.length != 1
      raise "Cannot determine device information for: #{re}"
    end
    return result.first
  end

  puts "  " + lines.getLineFromList(/Model Number/)
  puts "  Estimated erase time: " + lines.getLineFromList(/SECURITY ERASE/).sub(/ .*/, "")
end


#
# confirmWipe - confirm user wants to perform secure erase on this device
#
# Displays current partition table then prompts for yes/no response.
#
def confirmForWipe(dev)
  puts ""
  puts "Current partition table:"
  system("fdisk -l #{dev} | sed -e 's/^/  /'")
  puts ""
  puts "THIS DEVICE IS ABOUT TO BE COMPLETELY ERASED !!!"
  loop do
    print "Proceed to erase #{dev}? (yes/no) : "
    case gets.rstrip
    when "yes"
      return
    when "no"
      raise "Aborted by request"
    else
      puts 'Huh? Please answer "yes" or "no".'
    end
  end
end


#
# performWipe - perform ATA secure erase on a device
#
def performWipe(dev)
  pass="secretPassword"
  puts ""

  runCommand("hdparm --user-master u --security-set-pass #{pass} #{dev}")
  lines = getHdParamInfo(dev)
  if ! lines.include?("enabled")
    raise "Failed to set security password on device."
  end

  runCommand("hdparm --user-master u --security-erase #{pass} #{dev}")
  lines = getHdParamInfo(dev)
  if ! lines.include?("not enabled")
    raise "Failed to perform secure erase."
  end

  puts "Wipe command has completed."
end



#
# runCommand - run a command
#
# Displays a command to run, runs it, then checks exit status.
#
def runCommand(cmd)
  puts("+ #{cmd}")
  system(cmd)
  if $?.exitstatus != 0
    raise "Command failed with status: #{$?}"
  end
end


#
# verifyWipe - verify that a device has been wiped
#
# This is done by verifying that the first 500MB of the device
# is all zeroes.
#
def verifyWipe(dev)
  puts ""
  puts "Confirming wipe was successful ... stand by ~30 seconds ..."
  count=`dd if=#{dev} bs=1M count=#{WIPE_CHECK_MB} 2>/dev/null | tr -d '\\0' | wc -c`.rstrip
  if count != "0"
    raise "WIPE FAILED!! Disk still has data."
  end
  puts "Wipe is successful!"
end


##############################################################################
#
# begin execution
#

main
