require 'curb'
require 'nokogiri'
require 'csv'

def get_additive index
  return "?p=#{index}&content_only=1&infinitescroll=1"
end

def generate_url (url, index)
  return url + get_additive(index)
end

def get_html (url)
  http = Curl.get(url)
  Nokogiri::HTML(http.body_str)
end

def get_product_links url
  result = []
  xpath_to_product_link = '//div[@class="product-container"]/div/div/a/@href'

  page = 1

  begin
    target_url = generate_url(url, page)
    html = get_html(target_url)

    puts "Page ##{page}"

    links = html.xpath(xpath_to_product_link)

    links.each do |link|
        result.push(link)
    end

    page += 1
  end while links.size > 0

  return result
end


def get_product url
  begin
    product = Hash[]

    html = get_html(url)

    title = html.xpath('//h1/text()').first.content.strip.capitalize

    product['title'] = title

    attributes = []
    html.xpath('//div[@class="attribute_list"]/ul/li/label/span').each do |attribute|
      attributes.push(attribute.content)
    end

    variations = Hash[]
    while attributes.length > 0
      price = attributes.pop
      weight = attributes.pop

      variations[weight] = [price]
    end

    product['variations'] = variations

    img_url = html.xpath('//img[@id="bigpic"]/@src').first.content

    product["img"] = img_url

    return product
  rescue
    puts "Ther's a problem with #{url}"
  end
end


def write_csv(file, array)
  CSV.open(file, "a+") do |csv|
    csv << array
  end
end


def write_product (file, product)
  product['variations'].to_a.each do |variation|
    item = []
  
    title = "#{product['title']} - #{variation[0]}"
  
    price = variation[1][0].sub(",", ".").to_f
  
    img = product["img"]
  
    item.push(title, price, img)
  
    write_csv(file, item)
  end  
end


def main(url, file)
  puts "Script started to collect product links"
  product_links = get_product_links(url);

  wroteProducts = 0

  product_links.each do |link|
    begin
      product = get_product(link)
      write_product(file, product)
      
      wroteProducts += 1
      puts "Wrote #{wroteProducts} / #{product_links.length}"
    rescue
      puts "Sorry, but we cann't write this product"
    end
  end

  puts "Finished"
  puts "Have a nice day ;)"
end

url = ARGV[0]
file = ARGV[1]

main(url, file)
