task default: [:spec]

task :spec do
  exit system('rspec spec')
end