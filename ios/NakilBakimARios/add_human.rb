require 'xcodeproj'
project_path = 'NakilBakimAR.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'NakilBakimAR' }
group = project.main_group.find_subpath(File.join('NakilBakimAR'), true)
file_ref = group.new_reference('human.usdz')
target.resources_build_phase.add_file_reference(file_ref)
project.save
