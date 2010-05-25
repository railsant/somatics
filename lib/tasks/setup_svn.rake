desc "Configure Subversion for Rails"
task :setup_svn do
  system "svn info"
  if $? != 0
    puts 'Please Import your project to svn before executing this task' 
    exit(0)
  end
  
  puts "Removing /log"
  system "svn remove log/*"
  system "svn commit -m 'removing all log files from subversion'"
  system 'svn propset svn:ignore "*.log" log/'
  system "svn update log/"
  system "svn commit -m 'Ignoring all files in /log/ ending in .log'"
  
  puts "Ignoring /db" 
  system 'svn propset svn:ignore "*.db" db/' 
  system "svn update db/" 
  system "svn commit -m 'Ignoring all files in /db/ ending in .db'"

  puts "Renaming database.yml database.example" 
  system "svn move config/database.yml config/database.example" 
  system "svn commit -m 'Moving database.yml to database.example to provide a template for anyone who checks out the code'" 
  system 'svn propset svn:ignore "database.yml" config/' 
  system "svn update config/" 
  system "svn commit -m 'Ignoring database.yml'"

  puts "Ignoring /tmp" 
  system 'svn propset svn:ignore "*" tmp/' 
  system "svn update tmp/" 
  system "svn commit -m 'Ignoring all files in /tmp/'"

  puts "Ignoring /doc" 
  system 'svn propset svn:ignore "*" doc/' 
  system "svn update doc/" 
  system "svn commit -m 'Ignoring all files in /doc/'" 
end