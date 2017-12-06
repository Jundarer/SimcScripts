require 'rubygems'
require 'bundler/setup'
require 'csv'
require_relative 'lib/Interactive'
require_relative 'lib/JSONParser'
require_relative 'lib/JSONResults'
require_relative 'lib/SimcConfig'

classfolder = Interactive.SelectSubfolder('Combinator')
profile = Interactive.SelectTemplate("Combinator/#{classfolder}/Combinator")

#Read spec from profile
spec = ''
File.open("#{SimcConfig['ProfilesFolder']}/Combinator/#{classfolder}/Combinator_#{profile}.simc", 'r') do |pfile|
  while line = pfile.gets
    if line.start_with?('spec=')
      spec = line.chomp.split('=')[1]
    end
  end
end

gearProfile = Interactive.SelectTemplate("Combinator/#{classfolder}/CombinatorGear")
setupsProfile = Interactive.SelectTemplate('Combinator/CombinatorSetups')
talentdata = Interactive.SelectTalentPermutations()

# Recreate or append to csv?
csvFile = "#{SimcConfig['ReportsFolder']}/Combinator_Composite_#{profile}.csv"
Interactive.RemoveFileWithQuestion(csvFile)

# Read tier model from JSON
model = JSONParser.ReadFile("#{SimcConfig['ProfilesFolder']}/Fightstyles/Composite/Composite_#{setupsProfile}.json")

# Verify reports integrity
puts "verifying all reports needed..."
fightList = {}
lines = 0
buildDate = ""
model['Fightstyle_model'].each do |fight, value|
  # only if fightstyle value is > 0
  if value > 0 
    #check if csv file exists
    reportName = "#{SimcConfig['ReportsFolder']}/Combinator_#{fight}_#{profile}.csv"
    unless File.file?(reportName)
      puts "ERROR: Report missing : #{reportName} !"
      puts "Press enter to quit..."
      Interactive.GetInputOrArg()
      exit
    end
    
    #check if meta file exists
    reportNameMeta = "#{SimcConfig['ReportsFolder']}/meta/Combinator_#{fight}_#{profile}.json"
    unless File.file?(reportNameMeta)
      puts "ERROR: Report meta missing : #{reportNameMeta} !"
      puts "Press enter to quit..."
      Interactive.GetInputOrArg()
      exit
    end
    
    # check for same build date
    buildDateContent = JSONParser.ReadFile("#{SimcConfig['ReportsFolder']}/meta/Combinator_#{fight}_#{profile}.json")
    if buildDate == ""
      buildDate = buildDateContent['build_date']
    elsif buildDate != buildDateContent['build_date']
      puts "ERROR: Files don't have the same build date !"
      puts "Press enter to quit..."
      Interactive.GetInputOrArg()
      exit
    end
    
    # check for same number of lines
    if lines == 0
      lines = CSV.read(reportName).count
    elsif lines != CSV.read(reportName).count
      puts "ERROR: Files don't have the same length !"
      puts "Press enter to quit..."
      Interactive.GetInputOrArg()
      exit
    end
    
    # register fight
    fightList[fight] = value
  end
end

# Generate data
puts "Combining data from csv files..."
compositeData = {}
fightList.each do |fight, value|
  puts "Model #{fight} : #{value}" 
  
  reportName = "#{SimcConfig['ReportsFolder']}/Combinator_#{fight}_#{profile}.csv"
  
  #Store everything in the table
  CSV.foreach(reportName) do |row|
    key = row[0] + "," + row[1] + "," + row[2]
    
    #factor each data with the corresponding value
    if compositeData[key].nil?
      compositeData[key] = (value * row[3].to_f).round(0)
    else
      compositeData[key] = compositeData[key] + (value * row[3].to_f).round(0)
    end
  end
end

# Print data to file
puts "Writing data in #{csvFile} ..."
File.open(csvFile, 'a') do |csv|
  compositeData.each do |name, value|
    csv.write "#{name},#{value}"
    csv.write "\n"
  end
end

puts
puts 'Done! Press enter to quit...'
Interactive.GetInputOrArg()
