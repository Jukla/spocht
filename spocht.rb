#!/usr/bin/env ruby

require 'date'
require 'optparse'
require 'time'
require 'yaml'

options = {}
optionparser = OptionParser.new do |opts|
  options[:config_file] = __dir__ + '/spocht.yml'
  opts.on('-c','--config CONF', 'Absolute path to config file. Defaults to "spocht.yml" in same directory as script') do |conf|
    options[:config_file] = conf
  end

  options[:table] = false
  opts.on('-t','--table', 'Show table of training') do
    options[:table] = true
  end

  options[:list] = false
  opts.on('-l','--list', "List todays training") do
    options[:list] = true
  end
end.parse!

config                     = YAML.load_file(options[:config_file])
TRAINING_OF_DAY            = config['training_of_day']
EXERCISES_OF_TRAINING      = config['exercises_of_training']
TABLE_OF_TRAININGS_RANGE   = config['table_of_trainings_range']
TABLE_OF_TRAININGS_COLUMNS = config['table_of_trainings_columns']

unless (TRAINING_OF_DAY.values.uniq - EXERCISES_OF_TRAINING.keys.uniq).length == 0
  puts "There is/are training day(s) defined with missing exercises: #{(TRAINING_OF_DAY.values.uniq - EXERCISES_OF_TRAINING.keys.uniq).join(',')}"
end

## Returns the exercises of a training
def exercises_of_training(training)
  EXERCISES_OF_TRAINING[training]
end

## Returns the english day name of a year day number
def yday_to_day_name(yday = 0)
  Date.strptime(yday.to_s, "%j").strftime("%A")
end

## Returns the year day number of a given date.
## Defaults to today if date is nil
def yday(date)
  date = Time.now.strftime("%Y-%m-%d") if date.nil?
  if date.to_s =~ /^\d{1,3}$/
    Integer(date)
  else
    Integer(Date.parse(date).yday)
  end
end

## Returns the training of a date or yday
def training_of_date(date = nil)
  if yday(date) % TRAINING_OF_DAY.length == 0
    TRAINING_OF_DAY[TRAINING_OF_DAY.length]
  else
    TRAINING_OF_DAY[yday(date) % TRAINING_OF_DAY.length]
  end
end

## Return a 2D array like this:
## [
##   ["Sunday", "-"],
##   ["Monday", "-"],
##   ["Tuesday", "3x 6 Kreuzheben", "3x 6 KH-Rudern"],
##   ...
## ]
def table_of_tranings(date = nil, range = TABLE_OF_TRAININGS_RANGE)
  table = Array.new(){Array.new()}
  yday  = yday(date) - range  ## Becomes first day of series
  i     = 0
  while yday <= yday(date) + range do
    table.append([yday_to_day_name(yday)] + EXERCISES_OF_TRAINING[training_of_date yday])
    yday = yday + 1
    i    = i +1
  end
  return table
end

## Pretty prints a 2D array like table_of_tranings()
## NB() col_level is a starting point of many iterations and is increased by number_of_trainings_horizontally after all rows were processed
def prettify_table_of_trainings(table, number_of_trainings_horizontally = TABLE_OF_TRAININGS_COLUMNS)
  length_columns = table.length
  length_rows    = table.max_by(&:size).size
  row            = 0
  col_level      = 0
  while col_level < length_columns do
    col = col_level
    while col < length_columns do
      printf("%-50s ", table[col][row])
      col = col + 1
      break if col % number_of_trainings_horizontally == 0
    end
    puts
    row = row + 1
    if row > length_rows
      puts
      col_level = col_level + number_of_trainings_horizontally
      row       = 0
    end
  end
end

begin
  puts
  if options[:list]
    puts 'Todays training:'
    puts "  #{training_of_date}"
    EXERCISES_OF_TRAINING[training_of_date].each do |exercise|
      puts "    #{exercise}"
    end
  end

  if options[:table] or !options[:list]
    prettify_table_of_trainings(table_of_tranings)
  end
  puts
end
