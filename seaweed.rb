require 'nokogiri'
require 'pry'
require 'webdrivers'
require 'watir'

divider_large = "--------------------------------------------"
divider_short = '----------------------'
base_url = "magicseaweed.com/Sydney-Manly-Surf-Report/526/"
browser = Watir::Browser.new :firefox, headless: true
browser.goto(base_url)
js_graph = browser.div(class: "scrubber").wait_until(&:exists?)
js_tides = browser.div(class: "msw-tide-con").wait_until(&:exists?)
js_temp = browser.div(class: "msw-fc-current").wait_until(&:exists?)


js_graph_data = Nokogiri::HTML(js_graph.inner_html)
js_tide_data = Nokogiri::HTML(js_tides.inner_html)
js_temp_data = Nokogiri::HTML(js_temp.inner_html)

graph_columns = js_graph_data.css('.scrubber-group')

temps = js_temp_data.css("li p").text.strip.match(/(.*)(Air.*?c).*?(Sea.*?c)/)



puts divider_large
waves = []
day_labels = "   "
peak = 0

graph_columns.each do |column| 
    dates = column.css('.scrubber-graph-header h6')
    puts ""
    puts "Day: #{dates[0].text.strip}"

    if dates[0].text.strip === "Today"
        day_labels += "|  Now  "
    else 
        day_labels += "|  #{dates[0].text.strip}  "
    end
    puts ""
    puts "Date: #{dates[1].text.strip}" 
    puts ""
    puts divider_short

    bars = column.css('.scrubber-bar')
    

    bars.each do |bar|
        bar_data = JSON.parse(bar.attributes["data-tooltip"].value)
        height = bar_data["title"].gsub(/<.*?>/, "").strip
        puts "Time: #{bar_data["time"]}"
        puts "Wave height: #{height}"
        puts divider_short

        nums = height.match(/(\d+).*(\d+)/)
        if nums.nil?
            wave_height = height.match(/(\d+)/)[1].to_i.ceil
            peak = wave_height if wave_height > peak
            waves.push wave_height
        else
            wave_height_averaged = ((nums[1].to_i + nums[2].to_i) / 2).ceil
             peak = wave_height_averaged if wave_height_averaged > peak
            waves.push wave_height_averaged
        end
    end
end

puts
puts "Weather: #{temps[1].strip}"
puts "#{temps[2].gsub("Air", "Air temp:").strip}, #{temps[3].gsub("Sea", "Sea temp:").strip}"
puts "Current wind: #{js_temp_data.css("p.h5").text.strip}."
puts "Tides:"

js_tide_data.css("tbody")[0].css("tr").each do |tide_row| 
    puts  tide_row.text.strip
end
puts divider_large


day_labels += " |"
puts day_labels
puts
puts "ft"
puts
 for i in (peak).downto(1) do 
    wave_row = "#{i}  "
    for j in 0...waves.length do
        if waves[j] >= i
            wave_row += "*"
        else 
            wave_row += " "
        end
    end
    wave_row += "   "
    puts wave_row
end


browser.close



