=begin

  This exmaple illustrates the use of the Junos::Ez::Config::Utils library.  The code will load the contents
  of a configuration file and save the diff output to the file "diffs.txt".  Error checking/exception
  handling is also demonstrated.  If there are any errors, the "pretty-print" (pp) function will dump the
  contents of the result structure to stderr so you can see what it looks like.
  
=end

require 'net/netconf/jnpr'
require 'junos-ez/stdlib'
     
# login information for NETCONF session 

login = { :target => 'vsrx', :username => 'jeremy',  :password => 'jeremy1',  }

## create a NETCONF object to manage the device and open the connection ...

ndev = Netconf::SSH.new( login )
$stdout.print "Connecting to device #{login[:target]} ... "
ndev.open
$stdout.puts "OK!"

# attach the junos-ez objects to the ndev object ...

Junos::Ez::Provider( ndev )
Junos::Ez::Config::Utils( ndev, :cfg )

# begin a block to trap any raised expections ...
begin     
  
  # lock the candidate config 
  ndev.cfg.lock!

  # load the contents of the 'load_sample.conf' file
  # into the device.
  
  $stdout.puts "Loading changes ..."
  ndev.cfg.load! :filename => 'load_sample.conf'
  
  # check to see if commit-check passes.  if it doesn't
  # it will return a structure of errors
  
  unless (errs = ndev.cfg.commit?) == true
    $stderr.puts "Commit check failed"
    pp errs
    ndev.close      # will auto-rollback changes
    exit 1
  end

  # save the cnfig diff to a file ...
  File.open( "diffs.txt", "w") {|f| f.write ndev.cfg.diff? }
  
  # commit the changes and unlock the config
  
  $stdout.puts "Commiting changes ..."
  ndev.cfg.commit!
  ndev.cfg.unlock!
  
  $stdout.puts "Done!"
  
rescue Netconf::LockError
  $stderr.puts "Unable to lock config"
rescue Netconf::EditError => e
  $stderr.puts "Unable to load configuration"
  pp Junos::Ez::rpc_errors( e.rsp )
rescue Netconf::CommitError => e
  $stderr.puts "Unable to commit configuration"
  pp Junos::Ez::rpc_errors( e.rpc )
end

ndev.close
