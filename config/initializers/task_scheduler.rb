=begin

scheduler = Rufus::Scheduler.start_new

scheduler.every('5s') do
  puts "I am a sample background job performed at #{Time.now}"
end

scheduler.every('7s') do
  puts "I am another sample background job performed at #{Time.now}"
end

=end
