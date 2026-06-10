require 'xcodeproj'
project_path = 'ios/NakilBakimARios/NakilBakimAR.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'NakilBakimAR' }
group = project.main_group.find_subpath(File.join('NakilBakimAR'), true)
file_ref = group.new_reference('CosmonautSuit_en.reality')
target.add_file_references([file_ref])
project.save
